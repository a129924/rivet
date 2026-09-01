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
