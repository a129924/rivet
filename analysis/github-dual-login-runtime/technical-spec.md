# OAuth／PAT 登入 Runtime 技術規格

Topic：`github-dual-login-runtime`。依據：[requirements](requirements.md)。以下為已接受設計，未宣稱實作完成。

## 公開組裝與責任

新增 public、`Sendable` 的 `GitHubLoginService: LoginAuthenticating`。初始化接收 OAuth configuration、`GitHubOAuthDataProtectionStores`、正式 `GitHubPATDataProtectionStore` 與 caller-owned `GitHubLoginCoordinator`。OAuth credential view 依 configuration.clientID 綁定；測試注入面保持 internal。

同一邏輯儲存目標的所有 service instances 共用 coordinator；只要共用任一寫入目的地亦須共用。Coordinator 涵蓋整次登入及收尾，OAuth／PAT 互斥；重疊請求不啟動第二次流程，回既有 authenticationFailed，取消仍優先。它不提供跨程序鎖定。

組裝前提：目標沒有其他程序或仍可能 persist 的 provider 同時寫入。本 topic 不新增 writer 退休、session 管理或帳號切換。

## OAuth 與共用帳號驗證

OAuth 重用正式 session／exchange；選擇性採用 E013 loopback relay 與 MainActor browser opener，production 不 import experiments。保留 loopback-only、10 秒啟動及 300 秒授權界線；無效 callback 繼續等待，拒絕、逾時或啟動失敗轉有限 failure。

兩種方式以當次候選 token 共用 internal `/user` probe：沿用既有 Bearer 純轉換、bare HTTP、既有 Accept 與正式 runtime User-Agent。僅接受 HTTP 200、正整數 id、非空白 login；不建立 provider／scope、不呼 prepare、不 refresh、不自動 retry，避免驗證前觸發持久化。不保存 account identity。

## 保存與取消

驗證成功後才開始對應 store.save：OAuth 完整 credential bundle、PAT 正式 DPK actor。另一方式憑證保留，不記 active-mode。所有階段錯誤轉既有有限 failure，success 無 payload。

```text
authenticate(request)
  預先取消 → cancelled，零工作
  取得共用登入占用權
    已占用 → authenticationFailed
    OAuth → loopback＋瀏覽器＋正式交換
    PAT   → 本次 token
    /user 驗證
    提交前取消檢查
    對應 store.save
  等原工作、session 與 relay 收尾完成
  釋放占用權
  最後同步取消檢查 → cancelled／既定結果
  return；不再 await
```

取消傳遞給原工作並等待 settled。正式 relay 必須提供可等待 shutdown 屏障，不得只排程非同步 cancel 就回傳。提交前觀察取消則不保存；檢查後已開始的保存等待結束。保存成功後才觀察取消可回 cancelled，保留結果、不補償 delete／回寫舊值。收尾完成前 busy，釋放後最後同步檢查且無後續 suspension。

## 隔離、診斷與相容

既有登入 VO／Protocol／Outcome、正式 OAuth session／exchange、OAuth／PAT stores、provider／scope／clients、legacy、Presentation 與既有實驗來源皆 ReadOnly。測試依賴注入只開 internal，不擴公開 store API。診斷不輸出 token、secret、code、state、verifier、授權／callback URL 或原始錯誤。

不自動遷移或清理憑證。程式撤回不刪保存結果；未來驗收資料處置須另列 exact-owned 範圍與 Human 停點。

## 驗證與工具

TC01–TC08 見 [plan](../../plan/github-dual-login-runtime/github-dual-login-runtime.plan.md)。受控測試不呼真 GitHub／Security，競態使用 barrier、不以 sleep 推測。

Graphify 僅用既有可用圖 bounded query／path，再核對 revision 與 source；每次 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1，pin 0.9.73。無圖／過期／失敗則 rg／讀檔，不自動建圖、安裝、provider、hook、server 或上傳。

Archify 交付繁中 runtime sequence，固定 Viewer UI／HTML lang English fallback。Showcase 9 checks、0 errors、0 warnings；deliver receipts、四尺寸 visual-check 與人工看圖，視覺接受狀態分列，不發布 artifact.cafe。

PR Lens 僅在真實 base／head diff 後使用 pin 0.11.0，外部 topic 暫存目錄內建立含 real hashes、file refs、unchanged neighbors 的 map，validate／render。既有 config 僅套用不改；無 overlay 才用 --no-config。不偽造 provenance、不 npx／安裝／server／上傳／發布；不可用回報並直接 diff review，不代替 correctness review。
