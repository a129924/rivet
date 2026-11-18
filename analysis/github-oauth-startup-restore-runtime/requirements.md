# OAuth 冷啟動連線還原需求

## Goal / Non-Goal
提供正式 caller-owned OAuth 還原入口；從既存設定與憑證取得本地 ready scope 或明確未完成結果。本地 ready 不代表遠端身分、repository 權限或後續 request 成功。

## In-Scope / Out-Of-Scope
範圍限 GitHub.com、單一 OAuth、唯一 owner、正式組裝、必要刷新及完整保存、取消、busy、caller 明示重試、受控 consumer 與文件圖證據。
不含初次登入／設定、重新授權、清除、PAT、多帳號、產品 UI、PR 載入、新 storage、變更原登入 Outcome／provider／refresh／401 policy、跨程序、migration、真人 OAuth／DPK、E014 或全 repo mapping。

## 已鎖定決策
重疊立即 busy；一次 restore 只 prepare 一次，不自動重試。Provider 建立後永久沿用，不重讀 configuration、不快取 ready；取消等待原工作 settled，不回滾成功 rotation，不建立替代 writer。

## Acceptance Criteria
- AC1 正式入口，不依賴 experiments。
- AC2 未設定、未登入、authenticationRequired 與有限技術失敗可區分。
- AC3 必要保存成功後才 ready。
- AC4 取消不假成功、不回滾已完成保存。
- AC5 重試保持原 provider，terminal 不復活。
- AC6 重疊與收尾只有唯一 writer，無晚到 ready。
- AC7 不清除、登入或切換帳號。
- AC8 一般 import consumer 可使用公開 scope／clients；不宣稱遠端認證成功。

## 授權
Human 已採納對話計畫並授權在獨立 feature worktree 實作、按 topic commit、push、開 Draft PR，最終由 Human review。不得在 dev worktree 實作。時間邊界為 2026-11-17 18:20 Asia/Taipei；若尚有 required fix 或證據缺口，Draft PR 如實標 pending，不冒稱完成。

## 2026-11-18 Live 驗收追加授權
Human明確要求開始原未執行的live OAuth／DPK。原實作範圍與歷史證據保持；新增E018正式入口有限first/fresh驗證，不啟舊實驗、不做新登入／清除／強制到期。只因原credential自然到期而必要的正式refresh／save在授權內。
