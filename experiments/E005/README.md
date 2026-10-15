# E005：Keychain 本機完整 OAuth 憑證保存

## 驗證什麼
- 設計日期：2026-10-15；實驗編號 E005，由 Implementer 重查占用後建立，未覆寫 E001–E004。執行日期：2026-10-15，獨立 Tester。
- 問題：完全不依賴付費資格，完整六欄假憑證可否跨程序及同身分真重建還原，首次最多一次提示、其後零提示？
- 假設：存在符合上述條件的本機 Keychain 路徑；本輪只驗一個候選，不核准正式採用。

## 為什麼
- legacy 歷史八測試與 E004 不支持本輪完整 Keychain bundle／重建／UX 結論。
- TN3137、TN3125 及 DTS 836816／845980 指出兩種實作、host/profile 與 legacy 限制，仍須本機實證。
- [正式契約](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.plan.md)。

## 成功與失敗判準
- 寫入前固定：免費來源、完整還原、真同身分重建、替換、清理、首次最多一次提示／正常後續零提示均成立才成功。
- 前提滿足仍可重現不完整、讀不到或反覆提示為失敗。
- 身分／資格／觀察不足為無法判定；尚未嘗試為未執行。真 denial 無自然提示可保留缺口。
- 90 分鐘總額；02:41:28 UTC 起，03:56:28 停新增測量／圖作業，04:11:28 總上限。

## 環境與前置條件
- macOS 26.5.2（25F84），Apple Swift 6.3.3（swiftlang-6.3.3.1.3），arm64-apple-macosx26.0；版本證據見 [environment.json](evidence/environment.json)。
- 實驗 host 為 app-like CLI，以明確 ad-hoc 簽章，不建立憑證／帳號／profile。
- DPK 免費 profile 未建立且不進行新增帳號操作，首次寫入前選 legacy；selector false、sync false，全輪固定。這不證明 DPK 需要付費。
- 原始碼直接唯讀編譯既有三份 credential contracts，無 root manifest／production 修改或外部依賴。
- 所有資料為固定假值；namespace 為每輪 UUID。系統提示沒有人工觀察時必列未知，不以 exit code 推成零提示。

## 重現步驟
- `python3 experiments/E005/scripts/run_probe.py --backend legacy --out experiments/E005/evidence/normal-run.json`。
- runner 在系統暫存編譯 host：writer 結束→兩 fresh reader→marker 真重建／身分比較→正常替換→獨立負向→整輪 finally 清理。
- `--stop-after-write` 另用新 UUID 驗證提前停止清理，輸出至另一 evidence JSON。初版 early-stop 是正常 branch；修復後 controlled-stop 會明確 raise RuntimeError，經 exception path 進 finally。舊 receipts 保留不覆寫。
- 修復後 SIGINT／SIGTERM 轉為受控停止，finally 開始忽略重複同類訊號直到清理／receipt 完成。可重現 synthetic harness：`python3 experiments/E005/Tests/test_signal_cleanup.py`；fake build／identity／subprocess，不執行 Security。
- 重建身分不足不進行 acceptance read；恢復原 binary 只用於獨立 T04／T05 與清理，不作 T03 證據。
- 子程序正常退出保留項目；整輪正常／失敗／停止／例外統一精確清理主要與負向項目。

## 是否成功
- 執行日期：2026-10-15。正常 run：02:53:53.135235–02:54:00.436037 UTC；獨立提前停止 run：02:54:07.447658–02:54:10.198966 UTC。
- 實驗狀態：**無法判定**。正常 run 的 legacy 完整保存、fresh-process 還原、整筆替換及清理成功，但 ad-hoc 真重建後 designated requirement 不一致，且系統授權提示沒有人工觀察，無法滿足主要假設的同身分重建與 UX 前提。此不是 Keychain 機制失敗，也不能推論必須付費。
- 本輪 Keychain 驗證任務完成：**是**；已執行可用前提下的受限測量、記錄不足與決策限制，所有嘗試寫入項目已清理確認不存在。工具及整包交付由後續獨立 Reviewer 核對，不以此宣告完成。
- early-stop 與 controlled-stop receipt 的 `validationTaskComplete=false` 表示該 run 刻意不跑完整 T02–T05；其清理探針本身成功，不與正常 run 混合作同一筆憑證持久性證據。修復後 controlled-stop：02:57:52.206763–02:57:55.721547 UTC，新 UUID 真寫入後受控例外清理成功。

## 結果與證據
- 實際指令依上節順序，第二次為 `python3 experiments/E005/scripts/run_probe.py --backend legacy --stop-after-write --out experiments/E005/evidence/early-stop-run.json`。兩 run exit 0 只代表 runner 對應操作完成，不代表 UX 或主要假設成功。
- [normal-run.json](evidence/normal-run.json) 保存逐次 fresh subprocess 操作、時間、六欄布林值、遮蔽身分比較、namespace 及清理結果；[early-stop-run.json](evidence/early-stop-run.json) 為另一 UUID 的整輪停止清理證據。

| TestCase | 實際觀察與分類 |
| --- | --- |
| T01 前提 | 明確 legacy、selector false／sync false；app-like CLI ad-hoc signature verify 成功，沒有 team identifier／profile，不需憑證或付費資格。DPK 免費 host/profile 未確立，不能宣稱 DPK 不可用或需要付費。 |
| T02 完整還原 | 成功（資料機制）；writer 結束後兩個 fresh reader 的六欄均 true。提示次數均 null，UX 無法判定。 |
| T03 真重建 | 無法判定；實際 hash 改變且新簽章有效，路徑／bundle ID／簽章方式及 entitlements 比較相同，但 `designatedRequirementEqual=false`；未進行 acceptance read。還原舊 binary 只供 T04／T05／清理，不構成此案例證據。 |
| T04 完整替換 | 成功（資料機制）；在還原原身分後整筆替換 B，新程序六欄全 true。未支持新 binary 存取或 UX。 |
| T05 失敗邊界 | 真實 Keychain absent→nil、malformed→decode failure 成功。真 denial 未執行，沒有可用的自然提示觀察。synthetic 的 denied／cancelled／interactionUnavailable／unavailable 等分類皆 true，僅是函式注入分類證據，不能當真拒絕。 |
| T06 清理 | 正常 run 主要與負向兩項 delete／absence confirmed 皆 true；獨立 early-stop 寫入後故意停止，該主要項目亦 delete／absence confirmed true；負向項目未嘗試寫入。無已知殘留。 |

- Reviewer 回修後新增 [controlled-stop-run.json](evidence/controlled-stop-run.json)：真實 Keychain、新 UUID、`--stop-after-write` 受控例外路徑，精確 delete／absence confirmed 皆 true。初版 normal／early-stop 沒有 source hashes；新版 receipt 保存三 source SHA-256，不事後添加舊 provenance。Swift／build 不變，原 normal 六欄與同身分不足結論維持，沒有重跑或混用新舊 binary 持久性證據。
- [synthetic-sigint.json](evidence/synthetic-sigint.json) 與 [synthetic-sigterm.json](evidence/synthetic-sigterm.json) 為 **synthetic** 控制流程測試：fake write 登記後向本程序送真 OS 訊號，fake delete 中再送同訊號；兩個 testcase 成功，stopReason 對應訊號、所有假項目已追蹤並清理，receipt 均完整。這不證明真 Keychain 遭訊號中斷時的行為或 UX。
- 全部系統提示觀察維持 `unobserved`，所有 `promptCount` 為 null；沒有用程序成功、stderr 空白或操作耗時推論零提示。
- 真實 Security 操作與 synthetic 分類分開；JSON 不輸出 token、個人簽章識別或原始 system stderr。

## 結論與限制
- 本輪支持「此 ad-hoc legacy host 可跨 fresh process 保存／還原六欄假憑證並整筆替換」的受限結論；主問題仍無法判定，不支持正式採用。
- 下一個必要證據為免費且可重建後維持相同 designated requirement 的 host，以及首次／後續提示的實際人工觀察；需新增帳號或憑證操作時交還人類，不自行解除。DPK 免費前提仍未驗證。
- SIGINT／SIGTERM 受控停止有 synthetic 流程證據，寫入後受控例外有真 Keychain 清理證據；SIGKILL、程序 crash、host／系統失效無法保證 finally 清理，不將「所有退出路徑」外推至不可捕捉停止。若發生該類中斷須依 namespace／service／account／backend 人工恢復精確清理，不放寬安全設定。
- 只支持本次 OS、host、候選、簽章及假輸入；不外推產品登入、所有 macOS、公開分發或 provider runtime。

### 輔助工具交付

- [實驗 workflow](diagrams/keychain-workflow.html)、[delivery receipt](diagrams/keychain-workflow.delivery.json)、[四尺寸 receipt](diagrams/keychain-workflow.visual-check.json)、[另行視覺檢查](diagrams/visual-review.md)。Showcase 9/9、0 errors／warnings，四尺寸 containment 與明暗 captures 實際檢視通過；自動 `visualReview: pending` 原樣保留。作者內容繁體中文，固定 Viewer UI／HTML lang 使用 English fallback。
- [tooling.json](evidence/tooling.json)：Graphify 0.9.73 runtime 可用，但無可用 repository graph，依規範以限定 rg／source reads fallback，未 build／refresh。PR Lens 0.11.0 已確認 runtime，真實 topic commit 後才在 repository 外產生 bounded diff map，產物不發布；本檔不捏造尚未取得的 commit provenance。
- 獨立 Reviewer 已核對本輪受限成果及回修證據，明示 approved；這不改變主假設無法判定或核准採用。

### 交付與人類審查

本 topic 核心 commit `e6438ad` 已 push，已建立 [Draft PR #58](https://github.com/a129924/rivet/pull/58)，base 為 dev。全部 pre-commit hooks 通過；初次 renderer check 缺既有依賴快取，在 lockfile 相同下唯讀複用快取至 feature worktree 後通過，未安裝／更新依賴或修改 dev。PR Lens 0.11.0 已對核心 commit 的實際 diff 完成本機 validate／render；最終交付帳本 commit 後的 head 核對只在 repository 外進行，結果記於 Draft PR。圖表不是 correctness review。後續停於人類 review；主假設仍為無法判定，不核准採用或 merge。
