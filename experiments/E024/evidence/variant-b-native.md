# E024 · Variant B 原生驗收

2026-11-26，Asia/Taipei。arm64 macOS 26.5.2（25F84）、Xcode 26.6（17F113）、Swift 6.3.3、SwiftLint 0.65.1。整合基線 `41fdb0e`，合併提交 `57b448c`，原 E024 的 `9610830` 與證據保留。

## 受測產物

| 產物 | 識別 |
| --- | --- |
| E024 Variant B | `InboxI1Verification.app`，binary SHA-256 `5944d1c0aeeea67ef26a0ca0dda6ec06a4bc06cb0d188e9991ea59e33a972052` |
| Login 對照 | 既有 acceptance tool 同機建置，Welcome 17 pt，Light／Dark 各啟動一次。對照副本採獨立 bundle ID，binary 逐位元組與原工具產物一致，SHA-256 `da8ad0bfe3c4da92717f4740fed27eacaf2c3ea900b7e546ae5228fe96767a67`。 |
| 來源／原生紀錄 | [來源 SHA-256](variant-b-source-sha256.txt) · [原生 trace](variant-b-native.jsonl) · [同機原生截圖並排](variant-b-screens.png) |

截圖索引的同機原生視窗只裁掉擷取結果的空白留邊並等比例縮放。登入兩張對照使用同一份 Welcome binary，可比對內層 Surface、外層 Background、文字層級及 branch glyph。末段另以原尺寸收錄 2026-11-27 收到的兩張 Human 補證。

## 非原生驗證

- 紅：`swift test --filter InboxWorkspaceTests` 在 compact 版面尚未實作時，420／619 pt 判準如期失敗。
- 綠：獨立 Tester 在外部 scratch 與本機固定 Apollo 快取執行根套件 `swift test`，599 tests／74 suites 通過。另以獨立 scratch 執行 `INBOX_I1_RUN="$E024_SCRATCH" bash experiments/E024/scripts/verify.sh test`，7 tests／1 suite 通過。
- 五份變動 Swift 的 strict format、strict SwiftLint 和 `git diff --check` 通過。舊 E024 的 `native.jsonl` 和 `source-sha256.txt` 逐位元組核對一致。

## 原生觀察

| 案例 | 結果與界線 |
| --- | --- |
| A1-01 Light 鍵盤 | 通過。Shift-Tab 從 List 到原生 Picker，Tab 返回 List。Picker 內的方向／Enter、選不可開啟 C 後的 Enter，以及事件紀錄區內的 Enter，Open 增量皆為零。Home／End、方向鍵移動選取，B 可開啟時 Enter 恰記一筆。停用 Picker 保留 AX 語意。 |
| A1-02 非預設強調色 | 通過。多色與綠色對照都選 B，原生選列與啟用的 All segment 從系統藍色切到綠色，涵蓋 Light／Dark。Green 補驗使用 Shift-Tab 聚焦，截圖顯示 Picker 的原生輪廓及失焦 List 的灰色選列。同一強調色下的停用 Picker 截圖保留選項與停用外觀。Rivet 表面與文字角色仍可辨。驗後讀回多色。 |
| A1-03 Increase Contrast | 通過。在 Dark 可讀錯誤下比對 off／on，選列、靜態說明、分界、停用 Picker／重試皆可辨。原生焦點仍能操作。設定觀察為 Increase Contrast／Reduce Transparency `off/off → on/on → off/off`，最後值與原值一致。 |
| A1-04 Reduce Motion | 通過。off／on 下分別走可讀、窄版、空清單、不可讀錯誤、寬版。兩次都保留可讀選取，空與錯誤聚焦各自標題，Open 保持 3。補驗後設定回 off。 |
| A1-05 跨 App | 通過。Human 親測回覆 `PASS`，切到另一個 App 時 B 仍可辨識，回到 Inbox 後仍選 B。補附的兩張 Dark 截圖顯示 Inbox 作用中時 B 為藍色，以及 TextEdit 成為作用中視窗時 B 變為灰色，識別皆為 `sample/ui #42`，Open 數皆為 7。另一段原生操作中，TextEdit 的文字區接到 Return。Inbox trace 顯示 Open 維持 3，回到 List 後按 Enter 才恰加一筆 B。 |
| A1-06 VoiceOver | Human 實聽通過（回覆 `passed`）。核對範圍為 compact 的 Rivet 品牌朗讀一次、目前選列的完整 PR 識別／標題／選取、Picker 啟用／停用，以及載入／空清單／錯誤／離線各狀態。實聽結果來自 Human 對整組情境的回覆。AX 與截圖提供輔證。 |
| A1-07 完整受限寬度 | 通過。視窗內容實測 420 pt，List 配置區 396 pt。以未縮放的同機擷取量測原生選列的可見底色，Light／Dark 皆橫跨 x＝22～397（含端點），對應約 376 pt 的繪製寬度。Light／Dark 皆保有 compact 側欄、Header、Picker、Surface、List／狀態與事件區。長標題單行尾截斷，AX 保留完整文字與 `sample/ui #42`。縮放時維持 B，且不產生 Open。420 pt 下 Enter 恰記 B 一筆，放回 940 pt 仍選 B。 |

I1-01～07 以同一產物回歸。重排保留 B，移除 B 回退 A，過期 B 注入無效。載入後有效事件區焦點保持，原清單失效時轉至載入標題。空清單、未知可用性及無資料離線聚焦各自標題。可讀錯誤及可讀離線保留 B 和舊資料，復原停用。保存的 [trace](variant-b-native.jsonl) 是原始原生操作的前 76 筆，有效 Open 依序為 B、A、B、B、B。後續補驗和 Human 回覆記於上表，事件數可依各段操作核對。

## A1-05 真人補證 · 2026-11-27

兩張原始 PNG 均來自 Human，以下為附件 SHA-256。畫面與程式化 trace 為分開的取證。

| Dark 截圖 | 可觀察結果 | 原始 PNG SHA-256 |
| --- | --- | --- |
| Inbox 作用中 | Inbox 標題列顯示彩色視窗按鈕，B 的原生選列為藍色。 | `441feff51264d75db0e1dca928faae832faad5da606a29d3c972ae118d35a572` |
| TextEdit 作用中 | TextEdit 的視窗按鈕為彩色，空白文件可見文字插入點。背景 Inbox 的視窗按鈕呈灰色，B 保留灰色選取。 | `2eee441ea1564f8682ed0f01f8bb79452f2c0297782becffacf40b8ac7cb74cd` |

## 取證與採用狀態

A1 實作、獨立測試與 A1-05／06 的真人核對均已完成。420 pt 選列的量測取自原生截圖的選取底色邊界，396 pt 取自 List 的版面讀值。兩者記錄的對象不同。獨立成果複審 `approved`，Human 於 2026-11-27 確認正式採用 Variant B。 [正式採用與適用範圍](../../../docs/presentation/pr-inbox-visual-adoption.md)
