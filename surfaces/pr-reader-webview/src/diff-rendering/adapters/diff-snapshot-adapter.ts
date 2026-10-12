import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { DiffFacade } from "../facades/diff-facade";

export interface DiffSnapshotAdapter {
  receiveSnapshot(snapshot: DiffSnapshot): DiffRenderOutcome;
}

export function createDiffSnapshotAdapter(
  facade: Pick<DiffFacade, "present">,
): DiffSnapshotAdapter {
  return {
    receiveSnapshot(snapshot) {
      return facade.present(snapshot);
    },
  };
}
