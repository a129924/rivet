declare const validatedDiffInputBrand: unique symbol;
declare const parsedDiffInputBrand: unique symbol;
declare const renderPlanBrand: unique symbol;

export interface ValidatedDiffInput {
  readonly [validatedDiffInputBrand]: never;
}

export interface ParsedDiffInput {
  readonly [parsedDiffInputBrand]: never;
}

export interface RenderPlan {
  readonly [renderPlanBrand]: never;
}
