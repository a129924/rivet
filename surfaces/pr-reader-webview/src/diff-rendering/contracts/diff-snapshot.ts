import type { DiffViewModel } from "./diff-view-model";

export interface DiffSnapshot {
  readonly pullRequestId: string;
  readonly snapshotId: string;
  readonly files: readonly DiffViewModel[];
}
