import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { DiffOutputPort } from "../ports/diff-output-port";
import type { DiffParserPort } from "../ports/diff-parser-port";
import type { DiffRendererPort } from "../ports/diff-renderer-port";
import type { DiffViewModelValidatorPort } from "../ports/diff-view-model-validator-port";

export interface DiffRenderUseCaseDependencies {
  readonly validator: DiffViewModelValidatorPort;
  readonly parser: DiffParserPort;
  readonly renderer: DiffRendererPort;
  readonly output: DiffOutputPort;
}

export interface DiffRenderUseCase {
  execute(snapshot: DiffSnapshot): DiffRenderOutcome;
}

export function createDiffRenderUseCase(
  dependencies: DiffRenderUseCaseDependencies,
): DiffRenderUseCase {
  return {
    execute(snapshot) {
      const validationResult = dependencies.validator.validate(snapshot);
      if (validationResult.type === "error") {
        return validationResult;
      }

      const parseResult = dependencies.parser.parse(validationResult.value);
      if (parseResult.type === "error") {
        return parseResult;
      }

      const renderPlanResult = dependencies.renderer.createRenderPlan(
        parseResult.value,
      );
      if (renderPlanResult.type === "error") {
        return renderPlanResult;
      }

      return dependencies.output.output(renderPlanResult.value);
    },
  };
}
