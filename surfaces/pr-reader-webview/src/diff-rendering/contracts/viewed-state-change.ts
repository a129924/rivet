export interface ViewedStateChange {
  readonly pullRequestId: string;
  readonly snapshotId: string;
  readonly fileId: string;
  readonly viewed: boolean;
}
