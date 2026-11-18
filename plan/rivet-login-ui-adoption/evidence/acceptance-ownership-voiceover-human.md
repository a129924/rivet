# HC02：R3 新host的Human VoiceOver差異回報

- 日期：2026-11-18；owner=Human聲音觀察／Tester記錄。此檔為新增R3證據，不改原voiceover-human.md、H01–H08或HC01接受。
- 受測source HEAD9d14a3f6bf878a215de0d39d4fb05ec05970ec80，28項source manifest為3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988。
- Exact binary SHA-256：6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1；app tree ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae。
- 同一修正版Dark13／Standard、local.rivet.login-ui-acceptance；source／app未因聲音驗證改動。F01–F06已記在native證據，fallback已還原。
- 結果：Human確認下列兩組必要差異；交R07獨立核對證據與界線。**這是聲音／直接輸入結果，不是最終Human差異接受。HC02最終接受仍pending。**

## 方法與保留的未完成嘗試

Human最初回報「我做不出來」，因此改為Tester操作phase、Human只聆聽；Human另明示「已開啟旁白」。這不是元件failure，也沒有用代理AX觀察代替聲音。

前次問答卡流程包含「請重新開始」、單獨「有讀到」但尚未確認舊語音，以及「再一次 焦點都會跳來跳去不同的 ＡＰＰ」。該階段有跨App焦點干擾、回合未完成；不能推論唯一干擾來源或認定正式元件失敗，更不能將不完整回覆填成整組pass。

最後改用無問答卡方式：Tester以CUA選單切phase，依Human已明示的標準shell open方式將同一app帶回前景，停止操作；Human留在Rivet聽完／輸入測試字後，自行回對話用普通訊息回報。未新增快捷鍵、未修改任何系統設定／正式元件／host、未再操作被拒的Terminal UI。這是驗證方法調整，不覆寫原嘗試。

## V01：Account → Welcome

Tester依序選Verifying account、Welcome。CUA最終直接觀察Welcome與keyboard focus Continue with GitHub；不將此AX觀察當作聲音。

最後無問答卡回合，Human原文回報：

> 登入按鈕：有／沒有讀到 Continue with GitHub。 -> 有
>
> 舊語音：返回後，有／沒有才出現的帳號驗證語音。 -> 沒有

本輪可支持：有讀到指定登入按鈕，且在這次返回後沒有Human注意到的晚到帳號驗證語音。沒有取得完整最後一句逐字稿或VoiceOver cursor位置讀值；keyboard focus由AX另證，不能把兩者混成音訊trace。

## V02：Token → PAT

Tester依序選Verifying token、PAT。CUA最終直接觀察secure field、Personal access token label與keyboard focus到欄位；之後停止操作。Human被要求不點欄位，直接輸入幾個測試字；沒有要求真PAT，也不保存輸入內容。

Human原文回報：

> PAT 區塊：有／沒有讀到。 -> 有
>
> 直接輸入：可以／不可以。 -> 可以
>
> 舊驗證語音：返回後有／沒有才出現。 無

本輪可支持：有讀到PAT區塊、不點欄位可直接輸入、這次返回後沒有Human注意到的晚到舊驗證語音。最後沒有另行提交Human輸入、沒有認證／儲存或session。

## 收尾、界線與下一步

聆聽交接結束後，Tester只將同一app返回Welcome，離開PAT由正式局部行為清除測試輸入；直接AX／畫面確認Dark13／Standard乾淨Welcome，focus Continue with GitHub。CUA completion summary已送出「已完成原生與旁白補驗」。沒有為此rebuild、重跑完整矩陣或修改其他app／dev worktree。

- 以上是Human對話attestation，沒有音檔、完整逐字稿或所有OS語音佇列／race保證。
- 測試是有界序列切態，不宣稱量測過快速race；本輪未額外完整重驗所有重複／漏讀組合。
- 正式UI原HC01/source3c9baf3／preview42e99fa／binary4d...接受及H01–H08保持；9219的N案例與6a的F／V案例各保留版本，不改寫成全部新binary已測。
- 真Canvas操作仍未執行；不以native host／parent unit取代Canvas rendered證據。
- HC02聲音部分已取得上述實際回報，待獨立R07證據核對；**本輪驗收支援分離／封裝修正／新host差異的最終Human接受尚未明示**。這兩組case結果不能自動填成最終接受或merge授權。

`current_step: R07 Human聲音證據界線審查`；`next_step: HC02最終Human差異接受`；PR維持Draft、未merge。
