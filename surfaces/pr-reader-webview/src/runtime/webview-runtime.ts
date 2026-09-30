import type { DiffSnapshot } from "../diff-rendering/contracts/diff-snapshot";
import type { ViewedStateChange } from "../diff-rendering/contracts/viewed-state-change";
import { createDiffSnapshotAdapter } from "../diff-rendering/adapters/diff-snapshot-adapter";
import { createDiffParser } from "../diff-rendering/concrete-stages/diff-parser";
import { createDiffRenderer } from "../diff-rendering/concrete-stages/diff-renderer";
import { createDiffViewModelValidator } from "../diff-rendering/concrete-stages/diff-view-model-validator";
import { createDiffFacade } from "../diff-rendering/facades/diff-facade";
import {
  createDomDiffOutput,
  type DomDiffOutput,
} from "../diff-rendering/output/dom-diff-output";
import { createDiffRenderUseCase } from "../diff-rendering/usecases/diff-render-use-case";

interface HostMessage {
  readonly kind: "ready" | "renderResult" | "viewed";
  readonly generation: number;
  readonly snapshotId?: string;
  readonly outcome?: string;
  readonly pullRequestId?: string;
  readonly fileId?: string;
  readonly viewed?: boolean;
}

export function createWebViewRuntime(
  output: DomDiffOutput,
  post: (message: HostMessage) => void,
) {
  let generation = -1;
  const facade = createDiffFacade({
    useCase: createDiffRenderUseCase({
      validator: createDiffViewModelValidator(),
      parser: createDiffParser(),
      renderer: createDiffRenderer(),
      output,
    }),
    viewedStateChange: {
      notify(change: ViewedStateChange) {
        try {
          post({ kind: "viewed", generation, ...change });
        } catch {
          /* best effort */
        }
      },
    },
  });
  const adapter = createDiffSnapshotAdapter(facade);
  return {
    start(nextGeneration: number) {
      generation = nextGeneration;
      output.setInteractive(false);
      post({ kind: "ready", generation });
    },
    receiveSnapshot(snapshot: DiffSnapshot, deliveredGeneration: number) {
      if (deliveredGeneration !== generation) return;
      output.setInteractive(false);
      const outcome = adapter.receiveSnapshot(snapshot);
      const snapshotId =
        typeof snapshot?.snapshotId === "string" ? snapshot.snapshotId : "";
      post({
        kind: "renderResult",
        generation,
        snapshotId,
        outcome: outcome.type === "success" ? "success" : outcome.kind,
      });
      if (outcome.type === "success") output.setInteractive(true);
    },
    requestViewedStateChange(change: ViewedStateChange) {
      facade.requestViewedStateChange(change);
    },
  };
}

type RivetWindow = Window & {
  rivet?: ReturnType<typeof createWebViewRuntime>;
  webkit?: {
    messageHandlers?: { rivet?: { postMessage(message: HostMessage): void } };
  };
};

export function installWebViewRuntime(
  host: RivetWindow,
  document: Document,
): void {
  const root = document.getElementById("reader");
  if (root === null) throw new Error("Reader root is missing.");
  let runtime: ReturnType<typeof createWebViewRuntime>;
  const output = createDomDiffOutput(root, (change) =>
    runtime.requestViewedStateChange(change),
  );
  runtime = createWebViewRuntime(output, (message) => {
    const handler = host.webkit?.messageHandlers?.rivet;
    if (handler === undefined)
      throw new Error("WebKit message handler is missing.");
    handler.postMessage(message);
  });
  host.rivet = runtime;
}

if (typeof window !== "undefined" && typeof document !== "undefined") {
  installWebViewRuntime(window as RivetWindow, document);
}
