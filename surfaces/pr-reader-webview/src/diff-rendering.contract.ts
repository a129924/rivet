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

export interface ViewedStateChange {
  readonly fileId: string;
  readonly viewed: boolean;
}

export type DiffRenderOutcome =
  | { readonly type: "success" }
  | {
      readonly type: "error";
      readonly kind: "invalid-input" | "parse-error" | "render-error";
      readonly message: string;
    };

export declare const validatedDiffInputBrand: unique symbol;
export declare const parsedDiffInputBrand: unique symbol;
export declare const renderPlanBrand: unique symbol;

export interface ValidatedDiffInput {
  readonly [validatedDiffInputBrand]: true;
}

export interface ParsedDiffInput {
  readonly [parsedDiffInputBrand]: true;
}

export interface RenderPlan {
  readonly [renderPlanBrand]: true;
}

export type ValidationResult =
  | { readonly type: "success"; readonly value: ValidatedDiffInput }
  | {
      readonly type: "error";
      readonly kind: "invalid-input";
      readonly message: string;
    };

export type ParseResult =
  | { readonly type: "success"; readonly value: ParsedDiffInput }
  | {
      readonly type: "error";
      readonly kind: "parse-error";
      readonly message: string;
    };

export type RenderPlanResult =
  | { readonly type: "success"; readonly value: RenderPlan }
  | {
      readonly type: "error";
      readonly kind: "render-error";
      readonly message: string;
    };

export type OutputResult =
  | { readonly type: "success" }
  | {
      readonly type: "error";
      readonly kind: "render-error";
      readonly message: string;
    };

export interface DiffViewModelValidatorPort {
  validate(files: readonly DiffViewModel[]): ValidationResult;
}

export interface DiffParserPort {
  parse(input: ValidatedDiffInput): ParseResult;
}

export interface DiffRendererPort {
  createRenderPlan(input: ParsedDiffInput): RenderPlanResult;
}

export interface DiffOutputPort {
  output(plan: RenderPlan): OutputResult;
}

export interface ViewedStateChangePort {
  notify(change: ViewedStateChange): void;
}

export interface DiffRenderUseCase {
  execute(files: readonly DiffViewModel[]): DiffRenderOutcome;
}

export interface DiffFacade {
  present(files: readonly DiffViewModel[]): DiffRenderOutcome;
  requestViewedStateChange(change: ViewedStateChange): void;
}
