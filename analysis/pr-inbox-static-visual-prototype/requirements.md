# PR Inbox 靜態視覺原型：需求

## Goal

在 SwiftUI 實作前，提供一個可由本機瀏覽器直接開啟的 PR Inbox 桌面靜態原型，讓 Human 能以肉眼評估「等待我 review 的 PR」工作台之資訊層級、閱讀密度、優先閱讀順序與選取焦點，並決定採用、調整或放棄此視覺方向。

## Context

- 直接進入 SwiftUI 會讓資訊層級、閱讀密度與產品氣質的問題延後暴露；本 topic 以低成本 HTML mockup 先建立可觀察的 Human decision surface。
- 既有 `pr-inbox-swift-contract-baseline` correction 已取得獨立 Plan-Reviewer 明示 `approved`，因此該 prerequisite 已完成；此結果不構成本 topic 的 planning approval。
- 本 topic 的 PR-01 Plan-Reviewer verdict 為 `needs-rework`，唯一 required fix 是鎖定 RV-01 至 HC-01 的 routing；PC-02 只校正四份 artifacts，不構成 approval。校正後已收到新的獨立 PR-02 明示 `approved`，以本次核准的四份 artifacts 建立 TC-01 implementation baseline；IM-01 已 ready 但仍為 pending，尚未實作 HTML。

## Non-Goal

- 不建立 SwiftUI、Swift Package、product source、domain behavior 或正式 Presentation implementation。
- 不串接 GitHub API、`GithubIntegration`、authentication、account、cache、refresh、network 或 error handling。
- 不建立 PR Reader、PR 詳情、discussion、checks、files、diff 或 review 寫入。
- 不提供真實或可持久化互動、mobile／iPad layout、theme switcher 或完整 accessibility 驗證。

## In-Scope

- 一個固定深色、完全離線、自包含的 macOS 桌面 HTML mockup。
- 低干擾左側導覽，只聚焦 `Inbox` 與待 review 計數。
- 6 筆明顯虛構的 PR fixture；每筆包含標題、repository、作者、相對更新時間、0–2 個標籤與展示用摘要狀態。
- 第二列是唯一選取列；選取只代表 Presentation Session fixture，不屬於 PR Inbox domain。
- 同頁主要工作台下方提供一個獨立且清楚標示的空 Inbox frame。
- 1440px 桌面寬度完整呈現；1024px 桌面寬度依約收斂，且無水平 overflow。

## Ownership and Capability Boundaries

- PR Inbox 仍只擁有目前明確要求使用者 review 的 open PR 列表與排序語意；fixture 的顯示順序不鎖定或暗示正式 sorting policy。
- 目前選取項目仍屬 Presentation Session；HTML 中的選取列只是無互動、無持久化的視覺 fixture。
- PR Reader 與 `GithubIntegration` 邊界不變；原型不得暗示其資料、讀取、認證或寫入能力已存在。
- 不新增或修改 public API、Swift target、Domain model、Aggregate、Entity、Value Object、Port、Facade、Event、Message 或 Cross-BC contract。
- 原型不是長期架構真相，不新增或修改 `docs/architecture/`。

## Success Criteria

- 透過 `file://` 開啟單一 HTML 即可穩定檢視，不需網路、帳號、token、server、套件或 build step。
- 在 1440px 寬度可於主要 frame 一眼辨識個人待 review PR 工作台；標題、repository、作者及次要 metadata 有清楚層級，Inbox 清單維持主要注意焦點。
- 在 1024px 寬度，sidebar 縮窄、摘要隱藏、每列只保留第一個標籤、作者與更新時間位於單行，且標題與 repository 持續可辨識、頁面無水平 overflow。
- 固定深色視覺使用深灰表面、可讀的淺色文字與節制藍色 accent；不存在 theme switcher。
- 6 筆 fixture 中只有第二列具選取樣式，並清楚表達 selection 的 Presentation Session ownership。
- 獨立空 Inbox frame 在相同版面骨架中成立，與主要清單明確分隔。
- `Mockup` 標示與能力邊界清楚，畫面不暗示真實 GitHub／PR Reader／review 寫入或互動能力。
- Human 能明確回覆「採用」、「調整」或「放棄」。

## Failure and Stop Conditions

- 若原型無法讓 Human 判斷方向，回報 scope gap 並停止，不得默默加入真實資料、互動、PR Reader 或 GitHub 能力。
- 若 implementation 或 rework 需要變更指定 HTML 以外的檔案，停止並返回 planning。
- Plan-Reviewer 或 Reviewer 回報 `blocked`／`human-check` 時停止自動前進並交還 Human；`needs-rework` 只回交對應產出角色處理已列明的 required fixes。
- RV-01 只有明示 `approved` 才可進入 HC-01 的方向決策；`needs-rework` 只回交對應 Implementer，`blocked`／`human-check` 停止並交還 Human，且均不得視為成果核准或開啟 HC-01 的「採用／調整／放棄」。

## Human Check

完成 Tester 且 RV-01 明示 `approved` 後才停止於 HC-01。Human 選擇「採用」只允許另開正式 SwiftUI topic 進行規劃，不授權自動開始 SwiftUI implementation；「調整」回修本 topic 並重新驗證／審查；「放棄」則結束本方向。RV-01 的其他 verdict 不進入此方向決策。

## Last Updated

2026-09-11
