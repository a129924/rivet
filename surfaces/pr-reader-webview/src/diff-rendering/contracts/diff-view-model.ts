export type DiffFileStatus = "added" | "removed" | "modified" | "renamed";

export interface DiffViewModel {
  readonly fileId: string;
  readonly filename: string;
  readonly previousFilename?: string;
  readonly status: DiffFileStatus;
  readonly patch?: string;
  readonly additions: number;
  readonly deletions: number;
  readonly viewed: boolean;
}

export type DiffRenderOutcome =
  | { readonly type: "success" }
  | {
      readonly type: "error";
      readonly kind:
        | "invalid-input"
        | "parse-error"
        | "render-error"
        | "output-error";
      readonly message: string;
    };
