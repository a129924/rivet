// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { expect, test } from "bun:test";
import type { DiffSnapshot } from "../diff-rendering/contracts/diff-snapshot";
import type { DomDiffOutput } from "../diff-rendering/output/dom-diff-output";
import { createWebViewRuntime, installWebViewRuntime } from "./webview-runtime";

const snapshot: DiffSnapshot = {
  pullRequestId: "pr",
  snapshotId: "snapshot-1",
  files: [
    {
      fileId: "f:0",
      filename: "readme.md",
      status: "modified",
      additions: 0,
      deletions: 0,
      viewed: false,
    },
  ],
};

test("ready and render completion use current page generation", () => {
  const messages: unknown[] = [];
  const interactive: boolean[] = [];
  const output: DomDiffOutput = {
    output: () => ({ type: "success" }),
    setInteractive: (enabled) => {
      interactive.push(enabled);
    },
  };
  const runtime = createWebViewRuntime(output, (message) => {
    messages.push(message);
  });
  runtime.start(2);
  runtime.receiveSnapshot(snapshot, 1);
  expect(messages).toEqual([{ kind: "ready", generation: 2 }]);
  runtime.receiveSnapshot(snapshot, 2);
  expect(messages).toEqual([
    { kind: "ready", generation: 2 },
    {
      kind: "renderResult",
      generation: 2,
      snapshotId: "snapshot-1",
      outcome: "success",
    },
  ]);
  expect(interactive).toEqual([false, false, true]);
});

test("Viewed is best effort and render failure keeps controls disabled", () => {
  const messages: unknown[] = [];
  const interactive: boolean[] = [];
  const output: DomDiffOutput = {
    output: () => ({ type: "error", kind: "output-error", message: "failed" }),
    setInteractive: (enabled) => {
      interactive.push(enabled);
    },
  };
  const runtime = createWebViewRuntime(output, (message) => {
    messages.push(message);
  });
  runtime.start(3);
  runtime.receiveSnapshot(snapshot, 3);
  expect(messages.at(-1)).toEqual({
    kind: "renderResult",
    generation: 3,
    snapshotId: "snapshot-1",
    outcome: "output-error",
  });
  expect(interactive).toEqual([false, false]);
  runtime.requestViewedStateChange({
    pullRequestId: "pr",
    snapshotId: "snapshot-1",
    fileId: "f:0",
    viewed: true,
  });
  expect(messages.at(-1)).toEqual({
    kind: "viewed",
    generation: 3,
    pullRequestId: "pr",
    snapshotId: "snapshot-1",
    fileId: "f:0",
    viewed: true,
  });
});

test("browser installer registers the bridge and announces readiness", () => {
  const messages: unknown[] = [];
  const buttons: { click?: () => void; disabled?: boolean }[] = [];
  const makeNode = () => ({
    childNodes: [] as unknown[],
    dataset: {} as Record<string, string>,
    append(...items: unknown[]) {
      this.childNodes.push(...items);
    },
    replaceChildren(...items: unknown[]) {
      this.childNodes = items;
    },
    addEventListener(_name: string, listener: () => void) {
      this.click = listener;
    },
    click: undefined as (() => void) | undefined,
  });
  const document = {
    createElement: (name: string) => {
      const node = makeNode();
      if (name === "button") buttons.push(node);
      return node;
    },
    createDocumentFragment: makeNode,
    getElementById: () => root,
  };
  const root = { ...makeNode(), ownerDocument: document };
  const host = {
    webkit: {
      messageHandlers: {
        rivet: { postMessage: (message: unknown) => messages.push(message) },
      },
    },
  };
  installWebViewRuntime(host as never, document as never);
  expect(host).toHaveProperty("rivet");
  const runtime = (
    host as typeof host & {
      rivet: {
        start(generation: number): void;
        receiveSnapshot(snapshot: DiffSnapshot, generation: number): void;
      };
    }
  ).rivet;
  runtime.start(7);
  expect(messages).toEqual([{ kind: "ready", generation: 7 }]);
  runtime.receiveSnapshot(snapshot, 7);
  expect(messages.at(-1)).toEqual({
    kind: "renderResult",
    generation: 7,
    snapshotId: "snapshot-1",
    outcome: "success",
  });
  buttons[0]?.click?.();
  expect(messages.at(-1)).toEqual({
    kind: "viewed",
    generation: 7,
    pullRequestId: "pr",
    snapshotId: "snapshot-1",
    fileId: "f:0",
    viewed: true,
  });
});

test("missing WebKit message handler rejects startup instead of dropping ready", () => {
  const document = {
    getElementById() {
      return { ownerDocument: document };
    },
  };
  const host = {} as {
    rivet?: { start(generation: number): void };
  };
  installWebViewRuntime(host as never, document as never);
  expect(() => host.rivet?.start(1)).toThrow(
    "WebKit message handler is missing.",
  );
});
