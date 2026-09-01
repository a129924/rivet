import type { ViewedStateChange } from "../contracts/viewed-state-change";

export interface ViewedStateChangeAdapter {
  sendViewedStateChange(change: ViewedStateChange): void;
}
