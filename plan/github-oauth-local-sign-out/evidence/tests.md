# 獨立 Tester 驗證

日期：2026-11-13；branch：feat/github-oauth-local-sign-out；基線：2973150；受測為本次未提交 bounded diff。僅 fake Security／受控依賴，無真 OAuth／真 DPK item 操作。

## 親跑結果

- `swift test --filter 'OAuthLocalSignOutTests|GitHubOAuthDataProtectionStoresTests|OAuthTokenProviderTests'`：exit 0，44 tests／3 suites。
- `swift test`：exit 0，316 tests／39 suites。
- `scripts/check-github-integration-consumer.sh`：exit 0，15 tests／3 suites。
- `git diff --check`：exit 0。
- 暫存原始 logs：`rivet-signout-tester-focused.log`、`rivet-signout-tester-full.log`、`rivet-signout-tester-consumer.log`（系統暫存區，非持久證據；摘要以本文件保存）。

## 覆蓋限制，交 Reviewer 分類

T01–T07 有受控案例且親跑成功，但 T04 的 startedSaveSettlesBeforeDelete／failedPendingSaveStillClears 在建立 logout Task 後立刻開啟 save gate，沒有明確觀察 signOut 已先進入 actor 退休，因此該次交錯可能是 save 先完成；只證明 save→clear 事件順序，不能單獨當作 pending-write barrier 的決定性證據。

T08 的既有 client／provider 回歸通過；本輪沒有專屬測試涵蓋「已持有舊 scope 的 REST／GraphQL 後續工作與 401 recovery」。scope prepare retirement mapping 有受控測試。

T09／E016 未執行，缺 signed harness／簽章前提與 fresh-process 證據。不得以本次 tests 通過宣稱真 DPK 重啟驗收已完成。圖面檢查由主 agent 保存，本 Tester 未親跑或替代 Human 接受。

本次不作 correctness approval；證據交獨立 Reviewer。

## 回修獨立重驗（18:14）

Implementer 只修改測試與文件，無 production 改動。Tester 親跑 `swift test --filter OAuthLocalSignOutTests`：exit 0，11 tests／1 suite；`git diff --check` exit 0。暫存 log 為 `rivet-signout-tester-rework.log`。

T04 兩個 save 案例已在 save gate 關閉時，以 snapshot 得到 signedOut 握手，並確認 clears=0，再開 save gate；本輪成功結果支持退休發生於 save 結束前，補足先前假陽性缺口。握手附 1 秒 timeout 與 gate cleanup 避免永遠等待；因 snapshot 與 signOut task 的排程仍可競爭，若未來 timeout 應先分類 timing／flake，不直接判 production 錯誤。

T08 新增 retainedScopeCannotStartNewRESTOrGraphQLWork（兩 client 不 send）與 lateUnauthorizedResponsesCannotRecoverRetiredScope（兩 client 各一次已送 request，登出後晚到401不重送且不新增 save），皆親跑通過。

先前 T04/T08 覆蓋缺口已由這輪受控證據補足，交 Reviewer 作最終判定；T09／E016 真 DPK／fresh-process 仍未執行，不受此回修影響。

最終 helper 回修：Tester 再次親跑11 tests通過，diffcheck0；Reviewer明示受限code/tests approved，T04/T08 closed。T09未執行不變。
