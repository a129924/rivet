import type {
  DiffFileStatus,
  DiffRenderOutcome,
  DiffViewModel,
} from "./diff-view-model";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _status = Expect<
  Equal<DiffFileStatus, "added" | "removed" | "modified" | "renamed">
>;
type _viewModel = Expect<
  Equal<
    DiffViewModel,
    {
      readonly fileId: string;
      readonly filename: string;
      readonly previousFilename?: string;
      readonly status: DiffFileStatus;
      readonly patch?: string;
      readonly additions: number;
      readonly deletions: number;
      readonly viewed: boolean;
    }
  >
>;
type _outcome = Expect<
  Equal<
    DiffRenderOutcome,
    | { readonly type: "success" }
    | {
        readonly type: "error";
        readonly kind:
          | "invalid-input"
          | "parse-error"
          | "render-error"
          | "output-error";
        readonly message: string;
      }
  >
>;
