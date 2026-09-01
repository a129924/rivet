import type {
  DiffRenderOutcome,
  DiffViewModel,
} from "../contracts/diff-view-model";
import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { DiffOutputPort } from "../ports/diff-output-port";
import type { ViewedStateChangePort } from "../ports/viewed-state-change-port";
import type { DiffRenderUseCase } from "../usecases/diff-render-use-case";

export interface DiffFacadeDependencies {
  readonly useCase: DiffRenderUseCase;
  readonly output: DiffOutputPort;
  readonly viewedStateChange: ViewedStateChangePort;
}

export interface DiffFacade {
  present(files: readonly DiffViewModel[]): DiffRenderOutcome;
  requestViewedStateChange(change: ViewedStateChange): void;
}
