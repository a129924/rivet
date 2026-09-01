import type { DiffViewModel } from "../contracts/diff-view-model";

export interface DiffSnapshotAdapter {
  receiveSnapshot(files: readonly DiffViewModel[]): void;
}
