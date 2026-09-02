import type { ParsedDiffInput } from "../contracts/opaque-stage-inputs";
import type { RenderPlanResult } from "../contracts/stage-results";

export interface DiffRendererPort {
  createRenderPlan(input: ParsedDiffInput): RenderPlanResult;
}
