import type {
  ParsedDiffInput,
  RenderPlan,
  ValidatedDiffInput,
} from "./opaque-stage-inputs";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _validatedDiffInputIsOpaque = Expect<
  Equal<object extends ValidatedDiffInput ? true : false, false>
>;
type _parsedDiffInputIsOpaque = Expect<
  Equal<object extends ParsedDiffInput ? true : false, false>
>;
type _renderPlanIsOpaque = Expect<
  Equal<object extends RenderPlan ? true : false, false>
>;

type _opaqueStageInputsHaveNoRuntimeExports = Expect<
  Equal<keyof typeof import("./opaque-stage-inputs"), never>
>;

// @ts-expect-error Required module-private never brand rejects structural construction.
const _ordinaryObjectIsNotValidatedInput: ValidatedDiffInput = {};
// @ts-expect-error Required module-private never brand rejects structural construction.
const _ordinaryObjectIsNotParsedInput: ParsedDiffInput = {};
// @ts-expect-error Required module-private never brand rejects structural construction.
const _ordinaryObjectIsNotRenderPlan: RenderPlan = {};
