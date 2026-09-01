import type {
  ParsedDiffInput,
  RenderPlan,
  ValidatedDiffInput,
} from "./opaque-stage-inputs";

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
