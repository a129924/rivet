import type { DiffViewModel } from "../contracts/diff-view-model";
import type { ValidationResult } from "../contracts/stage-results";
import type { DiffViewModelValidatorPort } from "./diff-view-model-validator-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _validatorPort = Expect<
  Equal<
    DiffViewModelValidatorPort["validate"],
    (files: readonly DiffViewModel[]) => ValidationResult
  >
>;
