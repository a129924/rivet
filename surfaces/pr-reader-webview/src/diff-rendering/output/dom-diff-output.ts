import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import type { ViewedStateChange } from "../contracts/viewed-state-change";
import { readRenderPlan } from "../concrete-stages/diff-renderer";
import type { DiffOutputPort } from "../ports/diff-output-port";

export interface DomDiffOutput extends DiffOutputPort {
  setInteractive(enabled: boolean): void;
}

const allowedTags = new Set([
  "DIV",
  "SPAN",
  "TABLE",
  "THEAD",
  "TBODY",
  "TR",
  "TD",
  "TH",
  "PRE",
  "CODE",
  "BR",
  "UL",
  "LI",
  "B",
  "STRONG",
  "I",
  "EM",
]);
const droppedTags = new Set([
  "SCRIPT",
  "STYLE",
  "IFRAME",
  "OBJECT",
  "EMBED",
  "SVG",
  "MATH",
  "LINK",
  "META",
  "FORM",
]);

export function createDomDiffOutput(
  root: HTMLElement,
  requestViewedChange: (change: ViewedStateChange) => void,
): DomDiffOutput {
  const document = root.ownerDocument;
  let buttons: HTMLButtonElement[] = [];
  let interactive = false;

  return {
    output(plan: RenderPlan) {
      try {
        const data = readRenderPlan(plan);
        const fragment = document.createDocumentFragment();
        const nextButtons: HTMLButtonElement[] = [];
        for (const entry of data.entries) {
          const section = document.createElement("section");
          section.className = "diff-file";
          section.dataset.fileId = entry.file.fileId;
          const header = document.createElement("div");
          header.className = "file-header";
          const title = document.createElement("h2");
          title.textContent = entry.file.filename;
          const status = document.createElement("span");
          status.className = "file-status";
          status.textContent = entry.file.status;
          const counts = document.createElement("span");
          counts.className = "file-counts";
          const additions = document.createElement("span");
          additions.className = "additions";
          additions.textContent = `+${entry.file.additions}`;
          const deletions = document.createElement("span");
          deletions.className = "deletions";
          deletions.textContent = `−${entry.file.deletions}`;
          counts.append(additions, " / ", deletions);
          const button = document.createElement("button");
          button.type = "button";
          button.className = "viewed-button";
          button.textContent = entry.file.viewed
            ? "已 Viewed · 取消"
            : "標記 Viewed";
          button.disabled = true;
          button.addEventListener("click", () => {
            if (!interactive) return;
            interactive = false;
            for (const item of buttons) item.disabled = true;
            requestViewedChange({
              pullRequestId: data.pullRequestId,
              snapshotId: data.snapshotId,
              fileId: entry.file.fileId,
              viewed: !entry.file.viewed,
            });
          });
          header.append(title, status, counts, button);
          section.append(header);
          if (entry.kind === "metadata-unavailable") {
            const note = document.createElement("p");
            note.className = "metadata-note";
            // biome-ignore lint/security/noSecrets: Localized UI copy is not a credential.
            note.textContent = "此檔案只有變更資訊，沒有可顯示的 patch。";
            section.append(note);
          } else {
            const patch = document.createElement("div");
            patch.className = "patch";
            patch.append(sanitizeDiffHTML(entry.html, document));
            section.append(patch);
          }
          fragment.append(section);
          nextButtons.push(button);
        }
        root.replaceChildren(fragment);
        buttons = nextButtons;
        interactive = false;
        return { type: "success" } as const;
      } catch {
        return {
          type: "error",
          kind: "output-error",
          message: "Diff output failed.",
        } as const;
      }
    },
    setInteractive(enabled: boolean) {
      interactive = enabled;
      for (const button of buttons) button.disabled = !enabled;
    },
  };
}

/** Clone only display elements and text. Never copy event handlers or URL attributes. */
export function sanitizeDiffHTML(
  html: string,
  document: Document,
): DocumentFragment {
  const template = document.createElement("template");
  template.innerHTML = html;
  const safe = document.createDocumentFragment();
  for (const child of template.content.childNodes)
    appendSafe(child, safe, document);
  return safe;
}

function appendSafe(source: Node, target: Node, document: Document): void {
  if (source.nodeType === 3) {
    target.appendChild(document.createTextNode(source.textContent ?? ""));
    return;
  }
  if (source.nodeType !== 1) return;
  const element = source as Element;
  if (droppedTags.has(element.tagName)) return;
  if (!allowedTags.has(element.tagName)) {
    for (const child of element.childNodes) appendSafe(child, target, document);
    return;
  }
  const copy = document.createElement(element.tagName.toLowerCase());
  const classes = [...element.classList].filter((name) =>
    /^d2h-[a-zA-Z0-9_-]+$/.test(name),
  );
  if (classes.length > 0) copy.className = classes.join(" ");
  const colspan = element.getAttribute("colspan");
  if (colspan !== null && /^[1-9][0-9]?$/.test(colspan))
    copy.setAttribute("colspan", colspan);
  for (const child of element.childNodes) appendSafe(child, copy, document);
  target.appendChild(copy);
}
