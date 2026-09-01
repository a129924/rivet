import type { ValidatedDiffInput } from "../contracts/opaque-stage-inputs";
import type { ParseResult } from "../contracts/stage-results";

export interface DiffParserPort {
  parse(input: ValidatedDiffInput): ParseResult;
}
