import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type { ViewedStateChange } from "../contracts/viewed-state-change";
import type { ViewedStateChangePort } from "../ports/viewed-state-change-port";
import type { DiffRenderUseCase } from "../usecases/diff-render-use-case";

export interface DiffFacadeDependencies {
  readonly useCase: DiffRenderUseCase;
  readonly viewedStateChange: ViewedStateChangePort;
}

export interface DiffFacade {
  present(snapshot: DiffSnapshot): DiffRenderOutcome;
  requestViewedStateChange(change: ViewedStateChange): void;
}
