# E024 PR Inbox I1 原生驗證

## 驗證什麼

設計日期 2026-11-25。驗證公開的 RivetPresentation 元件加上實驗 Session，是否能在同一原生視窗維持選取、焦點及開啟事件的一致性。A 是 `sample/core#42`，B 是 `sample/ui#42`，C 是可選但不可開啟的 `sample/ui#43`。

## 為什麼

現有元件提供單選、焦點繫結、列主要動作及 Enter。首列回退、可用性、狀態標題與事件接收端由實驗負責。既有 List Preview 證據只涵蓋其 host。I1 的選取與焦點時序須以新視窗的原生操作核對。

[技術規格](../../analysis/pr-inbox-i1-verification/technical-spec.md) · [既有 List 驗收](../../plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md)

## 成功與失敗判準

I1-01 至 I1-08 均有符合事前判準的證據才成功。前置條件成立且觀察到違例時記失敗。尚缺必要證據時記無法判定。採一輪原生驗收，首輪實際發現 Home／End 無法選取首尾，在實驗視窗加上局部 AppKit 路由後補驗。此路由只在視窗內的清單有鍵盤焦點時處理未修飾的 Home／End，其餘手勢沿用既有清單。

[事前判準](../../plan/pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md#testcase)

## 環境與前置條件

arm64、macOS 26.5.2、Xcode 26.6、Apple Swift 6.3.3。套件部署基線為 macOS 15。受測基線 `e0cab03`，受測 Swift 檔及套件內容見 [SHA-256](evidence/source-sha256.txt)。測試及建置用 Apollo 2.1.2 的既有本機快取解析 root manifest。驗證 App 的資料、Open 目標、狀態及復原能力完全合成。

## 重現步驟

由 feature worktree 的 repository 根目錄執行下列命令。若 Apollo 快取放在其他位置，可用 `APOLLO_CACHE_SOURCE` 指定既有 bare repository。

```bash
export INBOX_I1_RUN="$(mktemp -d)"
bash experiments/E024/scripts/verify.sh test
bash experiments/E024/scripts/verify.sh build
open --stdout "$INBOX_I1_RUN/native.jsonl" \
  "$INBOX_I1_RUN/InboxI1Verification.app"
```

從初始 A 按 End，確認 C 被選取，按 Enter 應維持 0，再按 Home 回 A。對 A 按 Enter，再直接雙擊 B。使用「驗證情境」選單重排、移除 B、注入已移除的 B，並在清單焦點內按 Enter。可用「聚焦 Open 事件紀錄」測失焦和有效外部焦點。其餘情境及外觀也由同一選單切換。事件紀錄標示 `focus` 為觀察到的焦點、`requestedFocus` 為目的地、`injectedOpen` 為 Session 注入。原生拒絕可能在元件內停止，這時以原生畫面及事件總數的前後對照觀察。

## 是否成功

2026-11-25 完成建置、7 項 Swift Testing、嚴格 Swift 格式及 SwiftLint。完成原生滑鼠、鍵盤、選取和狀態焦點觀察。實驗整體為 **無法判定**，驗證工作尚未完成，I1-08 的實際 VoiceOver 聆聽及同環境 Login 並排仍待 Human review。受測事件路徑與 GUI 狀態已有部分證據，可供 Draft PR 審查。

## 結果與證據

[原生回修版事件紀錄](evidence/native.jsonl) 有 34 筆紀錄，Open 增量 `+1` 只有三次，依序為 A、B、A。受測 executable SHA-256 為 `0fba3c376cd62661ffe3de5cd8b309300ca473af1d08cef0f72426eb57486947`。

| 案例 | 實際觀察 |
| --- | --- |
| I1-01 | 起始 A。重排保留 B，移除 B 後回 A。兩次更新的 Open 增量皆為 0。 |
| I1-02 | Home／End 於回修版在 A 與 C 間移動。單擊、上下鍵只移動選取。Enter 從 A 開 A，從 A 雙擊未選 B 只記 B 一次。事件區有焦點時 Enter 無增量。 |
| I1-03 | C 及安全性未知的 B 經 Enter／雙擊均無增量。移除後注入 B 仍選 A、焦點留清單，累計維持 2。下一次原生 Enter 累計為 3，識別為 A。 |
| I1-04 | 載入隱藏列。事件區有焦點時保持，清單失效時轉至載入標題。 |
| I1-05 | 空清單無列，原生焦點落在空狀態標題。 |
| I1-06 | 可讀錯誤保留 B 與舊列，復原停用。不可讀及未知可用性隱藏列，焦點落錯誤標題。 |
| I1-07 | 可讀離線保留 B 與舊列，顯示可能非最新及停用的重新連線。無資料時焦點落離線標題。 |
| I1-08 | 已檢視本機 Inbox 的明暗截圖、原生選取與無障礙樹，並對照已封存的 Login 明暗畫面。原生 Inbox 使用系統表面，Login 參考圖有獨立色盤與品牌側欄。實際並排及 VoiceOver 聲音仍待人工核對。 |

## 結論與限制

現有公開元件加上 E024 的 Session 與局部鍵盤接線，在這個獨立視窗和固定合成資料中支持已觀察的原生操作。正式 Presentation 原始碼及根套件保持為此實驗的唯讀依賴。I1 採用判斷等待剩餘的人類驗收。真實 GitHub 資料、Reader 或正式產品導覽另行驗證。

## A1 · Variant B 驗收

A1 使用正式 `InboxWorkspace` 容器及既有原生 List／Picker。按上文命令建置並啟動 App。驗證情境選單增加「切換驗收用 Picker」、「切換長標題」及「內容寬度」的 420／940 pt 選項。Picker 預設停用。啟用只練習原生鍵盤和強調色，固定的 PR 資料及順序保持原樣。原 A／B／C 資料與舊 E024 證據仍可重現。

[Variant B 驗收紀錄](evidence/variant-b-native.md) · [原生 trace](evidence/variant-b-native.jsonl) · [明暗與窄版截圖索引](evidence/variant-b-screens.png)

真人驗收時，先在完整視窗選 B，切到另一個 App，觀察 Inbox 非作用中時的選列，再切回確認 B。VoiceOver 請核對 compact 品牌、完整選列標題、repository／PR 編號和選取狀態，並以情境選單逐一確認載入、空、錯誤及離線的焦點和實際朗讀。Picker 啟用與停用各確認一次。
