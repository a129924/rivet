// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { expect, test } from "bun:test";
import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import { createDomDiffOutput, sanitizeDiffHTML } from "./dom-diff-output";

class FakeNode {
  childNodes: FakeNode[] = [];
  textContent = "";
  readonly nodeType: number;
  constructor(nodeType = 1) {
    this.nodeType = nodeType;
  }
  appendChild(node: FakeNode): FakeNode {
    this.childNodes.push(node);
    return node;
  }
  append(...nodes: (FakeNode | string)[]): void {
    for (const node of nodes)
      this.appendChild(typeof node === "string" ? new FakeText(node) : node);
  }
  replaceChildren(...nodes: FakeNode[]): void {
    this.childNodes = nodes;
  }
}

class FakeText extends FakeNode {
  constructor(text: string) {
    super(3);
    this.textContent = text;
  }
}

class FakeElement extends FakeNode {
  className = "";
  disabled = false;
  type = "";
  dataset: Record<string, string> = {};
  attributes = new Map<string, string>();
  listeners = new Map<string, () => void>();
  constructor(
    readonly tagName: string,
    readonly ownerDocument: FakeDocument,
  ) {
    super();
  }
  get classList(): string[] {
    return this.className.split(" ").filter(Boolean);
  }
  getAttribute(name: string): string | null {
    return this.attributes.get(name) ?? null;
  }
  setAttribute(name: string, value: string): void {
    this.attributes.set(name, value);
  }
  addEventListener(name: string, callback: () => void): void {
    this.listeners.set(name, callback);
  }
  click(): void {
    this.listeners.get("click")?.();
  }
}

class FakeTemplate extends FakeElement {
  content = new FakeNode(11);
  set innerHTML(_html: string) {
    const script = new FakeElement("SCRIPT", this.ownerDocument);
    script.appendChild(new FakeText("bad()"));
    const link = new FakeElement("A", this.ownerDocument);
    link.setAttribute("href", "https://outside.invalid");
    link.appendChild(new FakeText("visible"));
    const div = new FakeElement("DIV", this.ownerDocument);
    div.className = "d2h-wrapper hostile";
    div.setAttribute("onclick", "bad()");
    div.append(script, link, new FakeText("patch"));
    this.content.appendChild(div);
  }
}

class FakeDocument {
  failFragment = false;
  createElement(name: string): FakeElement {
    return name === "template"
      ? new FakeTemplate("TEMPLATE", this)
      : new FakeElement(name.toUpperCase(), this);
  }
  createDocumentFragment(): FakeNode {
    if (this.failFragment) throw new Error("output unavailable");
    return new FakeNode(11);
  }
  createTextNode(value: string): FakeText {
    return new FakeText(value);
  }
}

function allNodes(node: FakeNode): FakeNode[] {
  return [node, ...node.childNodes.flatMap(allNodes)];
}

function plan(): RenderPlan {
  return {
    pullRequestId: "pr",
    snapshotId: "snap",
    entries: [
      {
        kind: "rendered",
        file: {
          fileId: "f:0",
          filename: "<reader>.swift",
          status: "modified",
          additions: 1,
          deletions: 2,
          viewed: false,
        },
        html: "<div>patch</div>",
      },
      {
        kind: "metadata-unavailable",
        file: {
          fileId: "f:1",
          filename: "binary.png",
          status: "copied",
          additions: 0,
          deletions: 0,
          viewed: true,
        },
      },
    ],
  } as unknown as RenderPlan;
}

test("output retains file order, text metadata and Viewed intent", () => {
  const document = new FakeDocument();
  const root = new FakeElement("MAIN", document);
  const changes: unknown[] = [];
  const output = createDomDiffOutput(root as unknown as HTMLElement, (change) =>
    changes.push(change),
  );
  expect(output.output(plan())).toEqual({ type: "success" });
  const nodes = allNodes(root);
  const sections = nodes.filter(
    (node) => node instanceof FakeElement && node.tagName === "SECTION",
  ) as FakeElement[];
  expect(sections.map((section) => section.dataset.fileId)).toEqual([
    "f:0",
    "f:1",
  ]);
  expect(nodes.some((node) => node.textContent === "<reader>.swift")).toBe(
    true,
  );
  expect(
    // biome-ignore lint/security/noSecrets: Localized UI copy is not a credential.
    nodes.some((node) => node.textContent.includes("沒有可顯示的 patch")),
  ).toBe(true);
  const buttons = nodes.filter(
    (node) => node instanceof FakeElement && node.tagName === "BUTTON",
  ) as FakeElement[];
  expect(buttons.every((button) => button.disabled)).toBe(true);
  output.setInteractive(true);
  buttons[0]?.click();
  expect(changes).toEqual([
    { pullRequestId: "pr", snapshotId: "snap", fileId: "f:0", viewed: true },
  ]);
  expect(buttons.every((button) => button.disabled)).toBe(true);
});

test("sanitizer removes executable elements, URL and event attributes", () => {
  const document = new FakeDocument();
  const result = sanitizeDiffHTML(
    "<div>patch</div>",
    document as unknown as Document,
  ) as unknown as FakeNode;
  const nodes = allNodes(result);
  expect(
    nodes.some(
      (node) => node instanceof FakeElement && node.tagName === "SCRIPT",
    ),
  ).toBe(false);
  expect(nodes.some((node) => node.textContent === "visible")).toBe(true);
  const div = nodes.find(
    (node) => node instanceof FakeElement && node.tagName === "DIV",
  ) as FakeElement;
  expect(div.className).toBe("d2h-wrapper");
  expect(div.attributes.size).toBe(0);
  expect(
    nodes.some(
      (node) => node instanceof FakeElement && node.attributes.has("href"),
    ),
  ).toBe(false);
});

test("output failure leaves the existing DOM intact", () => {
  const document = new FakeDocument();
  const root = new FakeElement("MAIN", document);
  root.appendChild(new FakeText("previous snapshot"));
  document.failFragment = true;
  const output = createDomDiffOutput(root as unknown as HTMLElement, () => {
    // This failure path must not emit a Viewed request.
  });
  expect(output.output(plan())).toEqual({
    type: "error",
    kind: "output-error",
    message: "Diff output failed.",
  });
  expect(root.childNodes[0]?.textContent).toBe("previous snapshot");
});
