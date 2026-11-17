# R02：原生補驗證據獨立審查

- 日期：2026-11-17；owner=Reviewer，獨立於 Swift 元件作者及本輪 Tester。
- 正式來源：`83543b07577b548b5d30edf174f33d1d49a65cd9`；branch `feat/rivet-login-ui-adoption`。
- **verdict: approved，僅限本輪 T02 補證、採用程度更新及既有 Draft PR #75 的文件更新。**
- **Required fixes：無；未發現需修改正式元件的可定位問題。** 不代表 VoiceOver、Human 最終 UI 接受或 merge 通過。

## 有界審查

依 `sdd-workflow-contract` 與 `feasibility-adoption-audit`，核對四份 topic artifacts 的 scope／驗收、T02 原生 AX／事件計數與代表性截圖交接、`evidence/native-ui.md`、step、README 及兩份長期文件差異。沿用 R01／post-rebase 的獨立 source review，不重做整份程式審查，也未重跑 GUI、build 或測試。

本輪差異只有 README、長期 UI／採用說明、topic 帳本與證據；`git diff HEAD --name-only -- Sources Tests experiments Package.swift` 為空，沒有 untracked 正式來源。外部 fake consumer 的可觀測性調整沒有進入 repository source。先前 361 root tests／46 suites、32 focused tests／7 suites仍是原有證據，本輪未重跑SwiftPM／單元測試，原生UI操作另有T02證據；未把舊測試結果冒充原生驗證。

## 證據與限制判定

| 項目 | 審查結果 |
| --- | --- |
| PAT 局部狀態 | N02–N11、N14–N15支持 Show／Hide、同 identity 切 failure 與字級／content 更新保留、trim 保內部空白、空白不送、提交立即清空／隱藏、離開／重設清除；E011 與 public consumer 的案例來源分開，未將 model tests 當原生互動。 |
| 回呼／外層邊界 | N04、N08–N13的 Events 0→10／Create 0→1支持七種 intents；停用 Create 無事件，啟用一次且保留輸入。fake parent處理事件並提供 phase，沒有真 VO 建構、認證、儲存或 session，也沒有 production Adapter。 |
| 48組矩陣 | 8畫面變體×2外觀×3字級是原生呈現／AX覆蓋；代表性視覺與捲動案例另列，未冒稱48張逐像素視覺比較。21pt表單可捲到Submit／footer的觀察支持受測尺寸可達性，不外推所有視覺組合。 |
| 焦點／宣告 | 可見鍵盤焦點、連續切態與後續Tab不被拉回有有限證據。Verifying／completed的AX heading及window鍵盤焦點不證明VoiceOver焦點、聲音或宣告時序；TC05的聽覺時序與TC06仍pending。 |
| 無效／歷史嘗試 | 原T01不可讀／aborted、早期AX索引失同步及timeout均保留且未算pass或產品failure；最後獨立wrapper重新逐步驗證。1秒process sample及首次272.124s工具等待沒有被外推為產品穩定性保證。 |
| 接受界線 | 舊版本Human接受不回填新版；本輪可觀察native補證與Human聲音／最終接受分開。沒有真認證整合、session建立、merge或發布的宣稱。 |

HC-FINAL 原「native互動仍未完成」摘要可能與T02混讀，已交作者修正；Reviewer讀回確認現為「T02可觀察native互動已補驗，VoiceOver及最終Human UI接受未完成」。README亦同步最新受限狀態，原T01歷史未改判。

## 採用程度

- LU-A01、LU-A02、LU-A04可列「已採用，限受測UI契約／介面」：既有正式實作與E011接入已有R01證據，本輪補足對應原生呈現、PAT狀態及callback行為；不是整體產品登入完成。
- LU-A03維持「部分採用」：鍵盤與所測切態行為已補證，VoiceOver聲音／焦點及宣告時序仍缺Human證據。
- LU-A05／LU-A06維持「已排除」：展示host與認證診斷不屬本topic正式UI採用；外部fixture不變成正式元件依賴。
- 原初次查核與Draft交付的部分採用歷史保留；沒有由缺tracker、測試數量或文件存在推定完成。

## 路由

可依既有人類授權提交／推送本topic文件補證並更新既有Draft，揭露上述限制。其後停HC01；VoiceOver與最終Human接受保持pending，不merge。

`current_step: R02 completed`；`next_step: HC01 pending`（先由獲授權交付者完成文件更新）；`status: COMPLETE`（本輪有界證據審查）；`verdict: approved`（僅本輪補證與Draft更新）。
