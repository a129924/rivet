# T03：Human VoiceOver 實際朗讀補驗

- 日期：2026-11-17；實際操作／聆聽及結果回報者=Human；Tester 整理對話證據，未自行聽取或錄製聲音。
- 正式來源：`1d5f2a0a06893b7b75ef5cc0a3848ad0be1b8097`，branch `feat/rivet-login-ui-adoption`；與 T02 的 Swift 元件來源相同，之間只有文件提交。
- 結果：下列受測 VoiceOver 內容、焦點、操作及兩組切態案例由 Human 回報正常。這是 Human 對當次實際聽覺的確認，不是音檔分析或所有時序的證明。
- 正式 SwiftUI、E011、Tests、Package、dev worktree 與系統設定未修改；本輪調整僅在外部假資料 host，repository 只補文件。
- **最終 Human 視覺／UI 接受仍 pending；TC06 的聲音部分已確認，不將整個 TC06 或 topic 宣稱完成，不 merge。**

## Human 操作與回報

前五項在 E011 原生主窗／既有 Demo Controls 操作；Controls 只供假 phase／失敗／完成切換。H06 是切回該主窗的定位確認。H07／H08 使用外部單窗 public consumer 的快捷鍵，在主窗仍作用中時提供 phase；正式元件不新增測試入口。只有測試文字，沒有真 token、OAuth、API、Keychain 或 session。

| ID | 操作／確認範圍 | Human 回報與判定 |
| --- | --- | --- |
| H01 | Welcome → GitHub waiting → Escape | Welcome 從 GitHub Connection 讀到 Continue with GitHub，最後讀出「按鈕」；等待與取消的意思都有；Escape 回到登入，沒有過期或重複朗讀。受測流程通過。 |
| H02 | PAT 初始欄位、Show／Hide、編輯及提交 | 自動移入並讀出欄位名稱／安全欄位「皆有」；Show／Hide 名稱及狀態清楚，可繼續編輯；提交後內容如規範，沒有重複、漏讀或上一畫面內容。通過。 |
| H03 | PAT 模擬失敗及再次提交 | Human 回報失敗「有讀出且可編輯」，再次提交驗證狀態正常朗讀；沒有重複、漏讀或過期語音。沒有額外逐字轉錄失敗內容或另量測焦點時間。通過受回報範圍。 |
| H04 | Complete simulation 成功狀態 | 有讀出模擬完成／未實際連接帳號；同輪確認沒有重複、漏讀或過期語音。通過，不代表 session 建立。 |
| H05 | GitHub 模擬返回、帳號驗證、browser failure、Retry／Escape | 帳號驗證正常朗讀；錯誤有讀出且焦點到 Try again；Retry 等待與 Escape 返回 Welcome 皆正常；重複、漏讀或過期語音皆無。通過。 |
| H06 | Controls 選 PAT 後切回主窗 | Human 點主窗頂端空白處，未直接點欄位；回報讀出 Personal access token 區塊且可正常輸入。支持回主窗後欄位可用，不代替快速切態結果。 |
| H07 | 同主窗 Account → Welcome，`⌘⇧1 → ⌘⇧2` | Human 明示第一組正常並要求保留。只依這項整組正常回報，不補造逐字語音、精確毫秒或獨立焦點紀錄；更新第二組按鍵後未要求重做第一組。 |
| H08 | 同主窗 Token → PAT，修正後 `⌘⇧7 → ⌘⇧8` | Human 回報朗讀 Personal access token 區塊、焦點在 PAT 欄位、能直接輸入，切換完成後沒有才新出現的舊驗證語音。通過。 |

以上沒有要求 Human 重做已確認的正常流程。H07／H08 是人類可操作速度及等待後的聽覺觀察，不是固定延遲、所有 sub-runloop race 或 OS 語音佇列的完整證明；沒有將已開始的語音與晚到舊宣告混為同一件事。

## 無效嘗試與 fixture 修正

1. 最初用獨立 Demo Controls 快速切 Account → Welcome、Token → PAT，Human 最後聽到「正在關閉選單／Simulate a failure checkbox」，焦點停在 Controls，不能直接輸入。這兩項受到跨視窗操作干擾，沒有算通過，也沒有定位為正式 UI 元件失敗。H06 另確認切回主窗後正常；不能以 H06 回填那兩項快速切態。
2. 為隔離控制窗焦點，外部既有 public consumer 加入四個同窗 menu 快捷鍵，只由假 parent 變更 phase。第一組 `⌘⇧1／2` 正常（H07）；第二組原 `⌘⇧3／4` 與 macOS 截圖快捷鍵衝突，Human 明示尚未驗證，不屬 UI 元件失敗。
3. 依 Human 限定要求，只將外部 host 第二組兩行 menu label／key equivalent 改為 `⌘⇧7／8`，第一組及事件處理不變。唯讀讀取已啟用的 macOS symbolic hotkeys，未找到這兩組綁定；沒有修改系統設定，也不保證其他自訂工具沒有全域攔截。
4. 外部 SwiftPM `LoginAdoptionProbe` 增量 build 通過（1.46 秒）。來源備份原放 target 內造成 unhandled-file warning，隨後移到外部 package 根目錄；不影響編譯結果，未修改 manifest 或正式 source，未為此重跑無關測試。
5. 停止前先核對唯一既有 host 的 executable 路徑與 SHA；SIGTERM 後身分檢查遇退出瞬間中止，當次未覆寫 binary；後續確認原 PID 不存在且沒有同路徑程序才更新既有 wrapper，重新啟動已讀回新程序。沒有停止其他 app 或建立平行 instance。
6. H08 是重新啟動修正後 host 的實際 Human 回報，沒有把建置、程序存在、靜態 menu 宣告或 AX 文字當作實際語音通過。

## 來源／fixture 追溯

外部 manifest 沿用 T02 的 Swift6／macOS15 public consumer，`Sources/Presentation` symlink 至 feature worktree 正式來源；root 780×500 pt，旁邊假控制區不屬正式 UI。外部快捷鍵 host 使用正式 `.standard` copy；H01–H06 的 E011 使用 host-owned 模擬 copy，兩者不混寫成同一文案。外部檔案以 `$VOICEOVER_SCRATCH` 表示，不將本機絕對路徑寫入 repository。

| 識別 | SHA-256 |
| --- | --- |
| E011 受測 executable（沿用 T02） | `7b63a99043763cad44fa48f2089cd39f00e6ea555acc0b6d7621f51fbc7ef669` |
| 四快捷鍵初版外部 source | `357dd2ed2d1511dd42a7c61cc7b0fba2724767b64f8e8f898f24c841bca0fb1b` |
| 四快捷鍵初版外部 binary（H07） | `25c7f33b641cf0dd68d141d1604be21f5d3898790e4595068e3e891529e46f22` |
| 第二組修正後外部 source | `a3ff19107f75a75e9a0affb011435d2b3c73d5f1971555c9aaa137d679976532` |
| 第二組修正後外部 binary（H08） | `c1558f2b90e4edf9a02a703d9a6079e3b90fc65da368f60532f36b711219dec9` |

原 source 及兩版 binary 在外部 scratch 留存，沒有改寫 T02 的 hash／當時結論。快捷鍵 host 留開供 Human 最終查看，不宣稱已結束或清空其當前表單；使用的字串都是假資料。沒有保存音檔或完整逐字稿，證據以本 topic 對話中 Human 回報及此有界整理為限。

## 採用與交接

依 T02 原生行為、既有獨立 source review 及本輪 Human 聲音確認，LU-A03 可列「已採用，限本次受測焦點／宣告／切態案例」；其方式仍是抽取調整並沿用取消 guard，沒有新增或搬入認證能力。此程度不代表 Human 最終視覺／UI 接受或所有環境保證，交獨立 Reviewer 檢查分類與證據一致性。

先前 root 361 tests／46 suites、focused 32 tests／7 suites及正式 Demo build 是既有同源結果，本輪沒有重跑 SwiftPM／單元測試；只有外部快捷鍵 host build 與 Human 操作新增證據。下一步沿既有成果審查審查本輪補證，無 required fix 時依既有授權更新 Draft，最終停 HC01 的視覺／UI 接受，不 merge。
