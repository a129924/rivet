import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { DiffOutputPort } from "../ports/diff-output-port";
import type { DiffParserPort } from "../ports/diff-parser-port";
import type { DiffRendererPort } from "../ports/diff-renderer-port";
import type { DiffViewModelValidatorPort } from "../ports/diff-view-model-validator-port";
import type {
  DiffRenderUseCase,
  DiffRenderUseCaseDependencies,
} from "./diff-render-use-case";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _dependencyKeys = Expect<
  Equal<
    keyof DiffRenderUseCaseDependencies,
    "validator" | "parser" | "renderer" | "output"
  >
>;
type _dependencies = Expect<
  Equal<
    DiffRenderUseCaseDependencies,
    {
      readonly validator: DiffViewModelValidatorPort;
      readonly parser: DiffParserPort;
      readonly renderer: DiffRendererPort;
      readonly output: DiffOutputPort;
    }
  >
>;
type _execute = Expect<
  Equal<
    DiffRenderUseCase["execute"],
    (snapshot: DiffSnapshot) => DiffRenderOutcome
  >
>;
