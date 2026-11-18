# dev 合入 conflict 修復：獨立 Tester 驗證

受測狀態：feature HEAD `a3271b2`、MERGE_HEAD `5713025`，尚未建立merge commit。Tester只驗證當前合併結果，未改source或conflict resolution。

- `swift test --filter 'StaticIsolationTests|OAuthLocalSignOutTests'`：exit0，59tests／4suites。
- `swift test --filter LoginAuthenticationContractTests`：exit0，8tests／1suite。合計67tests／5suites。
- `swift format lint --strict`檢查StaticIsolationTests與OAuthLocalSignOutTests：exit0。
- `git ls-files --unmerged`：空；cached及worktree `git diff --check`均exit0。
- 逐字核README：合併結果移除登入契約段即等於HEAD，移除登出段即等於MERGE_HEAD；兩topic原段落完整保留，未改寫既有文字。
- StaticIsolationTests allowlist已同時包含LoginAuthentication、OAuthCredentialClearingStore與OAuthSignOutError，親跑檢查通過。

沒有App launch、live DPK、sign、build驗收host或T09重做。歷史live受測source仍是bb6752a，不宣稱本次merge後binary已取得live驗證。明示交獨立Reviewer，非Tester correctness approval。
