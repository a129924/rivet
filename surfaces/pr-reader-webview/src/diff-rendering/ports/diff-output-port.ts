import type { RenderPlan } from "../contracts/opaque-stage-inputs";
import type { OutputResult } from "../contracts/stage-results";

export interface DiffOutputPort {
  output(plan: RenderPlan): OutputResult;
}
