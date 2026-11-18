# D01／D02：Topic commit、整合驗證與 Draft 交付

- 日期：2026-11-17；topic：`rivet-login-ui-adoption`。
- Human 已明示授權無重大問題直接 topic commit → push → Draft PR → Human review，未授權 merge。
- Branch：`feat/rivet-login-ui-adoption`；[Draft PR #75](https://github.com/a129924/rivet/pull/75)，base=`dev`。
- 實作 commit：`d762f935ec2d4e220e7bc2135e6b80daa21bef3e`；訊息：`feat(login-ui): 元件化登入介面並分離展示接線`。
- 原查核 base：`1f31b35604adb5bb36326e52f9d6dbcff0cac763`；交付整合 base：`ab77391b73291deb1ce3d96cef72f981aeb3104a`。

## Commit 與上游整合

32檔 staged diff 為同一UI topic：正式元件／E011／測試／四份規劃與證據／長期docs／Archify後繼圖。無認證或Package修改，staged diff-check通過。

第一次commit hook因新worktree缺本地Biome dependency而未完成；依docs/toolchain在該feature的renderer目錄執行`bun install --frozen-lockfile`，lockfile與config無改，重跑全部hooks通過：whitespace／EOF、Swift format、GitHubIntegration consumer contract、SwiftLint、renderer format／lint／typecheck。沒有skip／bypass。

初版commit `cd49069`尚未push時，上游已合併runtime與舊測試fake修正。feature乾淨rebase至新dev，無衝突，形成上列實作commit。13份已審UI／E011／測試來源逐bytes未變；Reviewer另做post-rebase有界查核並延續approved，僅放行Draft。

## 整合後實際檢查

| 檢查 | 結果 | 限制 |
| --- | --- | --- |
| feature root `swift test --disable-automatic-resolution` | exit0；361 tests／46 suites，3.458s測試時間 | 由交付root執行；不冒稱Tester重跑，也不等於native控件已驗 |
| feature root `swift build --disable-automatic-resolution --product RivetLoginDemo` | exit0；0.84s | 沒有重新嘗試native窗口／GUI |
| rebase前後已審來源 | 13檔bytes相同；Reviewer獨立核對 | auth／Package沒有topic diff |

root整合log保留repo外，以`$ROOT_LOG`表示；SHA-256：`fbe7994758046d53cb309a9e51dc278e226423e267a11c17b4deec4eb7bcbd64`。舊T01 root編譯失敗與其base依據原樣保留，不回填為當時pass。

## Draft 與 Human 停點

已將實作commit push至同名origin branch，透過GitHub connector建立Draft #75；PR明列root／focused／圖面結果、舊基線歷史與native TC02／03／05及Human VoiceOver／最終接受pending。後繼docs-only交付紀錄仍屬同topic，不修改已審Swift來源。

PR Lens僅針對實際base／最終head於repo外產生local map，結果與精確head以PR及最後交付回覆為準，不上傳或附加資產。Graphify標準位置無可用graph，採bounded source fallback，不自動extract／install／refresh或修改config。

## 測試process收尾補充

Tester交接後，root核對E011 PID38714的exact本次scratch wrapper與binary SHA `7b63a99043763cad44fa48f2089cd39f00e6ea555acc0b6d7621f51fbc7ef669`，僅對該PID送SIGTERM；後續ps exit1確認已結束。pgrep LoginAdoptionProbe exit1未找到process。未操作其他app，不改寫Tester最後觀察，也不因此宣稱native pass。

目前停HC01 Human review。TC02／03／05 native、TC06 VoiceOver與最終UI接受維持pending，LU-A02／03／04部分採用不變；沒有merge、tag或發布。
