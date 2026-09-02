import type { ValidatedDiffInput } from "../contracts/opaque-stage-inputs";
import type { ParseResult } from "../contracts/stage-results";
import type { DiffParserPort } from "./diff-parser-port";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _parserPort = Expect<
  Equal<DiffParserPort["parse"], (input: ValidatedDiffInput) => ParseResult>
>;
