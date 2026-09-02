import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { ValidationResult } from "../contracts/stage-results";

export interface DiffViewModelValidatorPort {
  validate(snapshot: DiffSnapshot): ValidationResult;
}
