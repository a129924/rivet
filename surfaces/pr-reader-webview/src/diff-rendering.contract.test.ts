import type {
  DiffFacade,
  DiffFileStatus,
  DiffOutputPort,
  DiffParserPort,
  DiffRenderOutcome,
  DiffRenderUseCase,
  DiffRendererPort,
  DiffViewModel,
  DiffViewModelValidatorPort,
  OutputResult,
  ParseResult,
  ParsedDiffInput,
  RenderPlan,
  RenderPlanResult,
  ValidatedDiffInput,
  ValidationResult,
  ViewedStateChange,
  ViewedStateChangePort,
} from "./diff-rendering.contract";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;

type Expect<Condition extends true> = Condition;

type Snapshot = readonly DiffViewModel[];

type _diffFileStatus = Expect<
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
type _viewedStateChange = Expect<
  Equal<
    ViewedStateChange,
    { readonly fileId: string; readonly viewed: boolean }
  >
>;
type _validatedDiffInputIsOpaque = Expect<
  Equal<object extends ValidatedDiffInput ? true : false, false>
>;
type _parsedDiffInputIsOpaque = Expect<
  Equal<object extends ParsedDiffInput ? true : false, false>
>;
type _renderPlanIsOpaque = Expect<
  Equal<object extends RenderPlan ? true : false, false>
>;
type _outcome = Expect<
  Equal<
    DiffRenderOutcome,
    | { readonly type: "success" }
    | {
        readonly type: "error";
        readonly kind: "invalid-input" | "parse-error" | "render-error";
        readonly message: string;
      }
  >
>;

type _validationResult = Expect<
  Equal<
    ValidationResult,
    | { readonly type: "success"; readonly value: ValidatedDiffInput }
    | {
        readonly type: "error";
        readonly kind: "invalid-input";
        readonly message: string;
      }
  >
>;
type _parseResult = Expect<
  Equal<
    ParseResult,
    | {
        readonly type: "success";
        readonly value: ParsedDiffInput;
      }
    | {
        readonly type: "error";
        readonly kind: "parse-error";
        readonly message: string;
      }
  >
>;

type _validationSuccessFlowsToParser = Expect<
  Equal<
    Extract<ValidationResult, { readonly type: "success" }>["value"],
    Parameters<DiffParserPort["parse"]>[0]
  >
>;
type _parseSuccessFlowsToRenderer = Expect<
  Equal<
    Extract<ParseResult, { readonly type: "success" }>["value"],
    Parameters<DiffRendererPort["createRenderPlan"]>[0]
  >
>;
type _renderPlanSuccessFlowsToOutput = Expect<
  Equal<
    Extract<RenderPlanResult, { readonly type: "success" }>["value"],
    Parameters<DiffOutputPort["output"]>[0]
  >
>;
type _renderPlanResult = Expect<
  Equal<
    RenderPlanResult,
    | { readonly type: "success"; readonly value: RenderPlan }
    | {
        readonly type: "error";
        readonly kind: "render-error";
        readonly message: string;
      }
  >
>;
type _outputResult = Expect<
  Equal<
    OutputResult,
    | { readonly type: "success" }
    | {
        readonly type: "error";
        readonly kind: "render-error";
        readonly message: string;
      }
  >
>;

type _validatorPort = Expect<
  Equal<
    DiffViewModelValidatorPort["validate"],
    (files: Snapshot) => ValidationResult
  >
>;
type _parserPort = Expect<
  Equal<DiffParserPort["parse"], (input: ValidatedDiffInput) => ParseResult>
>;
type _rendererPort = Expect<
  Equal<
    DiffRendererPort["createRenderPlan"],
    (
      input: import("./diff-rendering.contract").ParsedDiffInput,
    ) => RenderPlanResult
  >
>;
type _outputPort = Expect<
  Equal<DiffOutputPort["output"], (plan: RenderPlan) => OutputResult>
>;
type _useCase = Expect<
  Equal<DiffRenderUseCase["execute"], (files: Snapshot) => DiffRenderOutcome>
>;
type _facadePresent = Expect<
  Equal<DiffFacade["present"], (files: Snapshot) => DiffRenderOutcome>
>;
type _facadeViewedStateChange = Expect<
  Equal<
    DiffFacade["requestViewedStateChange"],
    (change: ViewedStateChange) => void
  >
>;
type _facadeMethods = Expect<
  Equal<keyof DiffFacade, "present" | "requestViewedStateChange">
>;
type _viewedStateChangePort = Expect<
  Equal<ViewedStateChangePort["notify"], (change: ViewedStateChange) => void>
>;
