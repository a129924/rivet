import type { DiffSnapshot } from "../contracts/diff-snapshot";

export interface DiffSnapshotAdapter {
  receiveSnapshot(snapshot: DiffSnapshot): void;
}
