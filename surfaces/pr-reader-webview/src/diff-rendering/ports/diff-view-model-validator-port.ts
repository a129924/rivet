import type { DiffViewModel } from "../contracts/diff-view-model";
import type { ValidationResult } from "../contracts/stage-results";

export interface DiffViewModelValidatorPort {
  validate(files: readonly DiffViewModel[]): ValidationResult;
}
