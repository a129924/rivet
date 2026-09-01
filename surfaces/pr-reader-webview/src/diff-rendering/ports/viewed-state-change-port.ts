import type { ViewedStateChange } from "../contracts/viewed-state-change";

export interface ViewedStateChangePort {
  notify(change: ViewedStateChange): void;
}
