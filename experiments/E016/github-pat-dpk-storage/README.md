# E016 — PAT DPK 儲存驗證

本 host 只屬於 `github-pat-dpk-storage`，一般 `import GitHubIntegration` 直接使用正式 `GitHubPATDataProtectionStore`。沒有登入、網路、真 PAT 輸入或產品 delete；刪除只在 owned cleanup 使用精確 group／service／`pat` account。Root package 不反向依賴 E016。

目前只交付工具與離線結果。**真 DPK、有效簽章環境、跨程序／重建還原、Human 提示與真項目清理均未執行，維持 pending。** 不繼承 E015 的窗口、ready、真人結果或歷史項目清理權限。E007 profile renewal 限制保持。

## 離線入口

在 repository root：

```sh
python3 -B experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py --help
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -v
xcodebuild -project experiments/E016/github-pat-dpk-storage/PATStorageProbe.xcodeproj \
  -scheme PATStorageProbe -configuration Debug -derivedDataPath "$RIVET_PAT_BUILD" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build
"$RIVET_PAT_BUILD/Build/Products/Debug/PATStorageProbe.app/Contents/MacOS/PATStorageProbe" --self-test
```

`RIVET_PAT_BUILD` 必須是本次獨立建置 scratch。Unsigned binary 只准以上明確 `--self-test` fake-only 分支；不是 GUI／真 DPK 啟動方法。Rebuilt 使用另一個 scratch、scheme `PATStorageProbeRebuilt` 與 configuration `Rebuilt`。兩 variant 的編譯條件不同。

Swift self-test 直接呼叫 live 也使用的 `Probe.perform`，但注入記憶體 store／journal：驗保存 A、替換 B、讀回、無 ownership 不刪除、寫入失敗仍保留 ownership 可清理，以及 marker 寫入失敗時零保存。Python 測試涵蓋實際 prepare／context／publish／observation／export 與 readiness guards，不呼 Security／sign／launch。

## 未來有 Human 在場時

以下是操作說明，**不是本輪 live 已完成或自動放行**。每段由 Human 明確表示就緒後才帶 `--human-ready`；前段程序未結束、來源／身分不明、unknown 或提示超標時停止依賴段。不可沿用舊 ready。

1. 用已存在的有效私有 access group，在 repository 外的私有父目錄執行 `prepare --repo "$RIVET_PAT_REPO" --parent "$RIVET_PAT_PARENT" --access-group "$RIVET_PAT_GROUP"`。產生唯一 0700 run root；其中 JSON 為 0600，不提交私人目錄。
2. 在私有 0600 settings JSON 指定已選的 `team`、`identity`、`profile` 三欄：`identity` 必須是已選 certificate 的 40 位十六進位 SHA-1（大小寫皆可），`profile` 是已選 profile 的 Name，不填通用 identity 名稱。不得建立／更新 Apple assets，不使用 provisioning updates。`build --root "$RIVET_PAT_RUN" --variant debug --settings "$RIVET_PAT_SETTINGS" --human-ready` 預設 `--signing-style manual`，將選定 SHA-1／profile Name 作 manual build settings。需要相容已存在的 Xcode-managed profile 時，明確加 `--signing-style automatic`；只重用已快取資產，帶 Automatic／Apple Development 並清空 profile specifier，不帶 provisioning updates／device registration。缺資產就失敗，不下載、不建立新 certificate／profile、不自動重試。兩模式在 copy 到 current、發布 identity 或 build proof 前，都核新 built app 的 Team、profile Name、certificate SHA-1 與三欄 pin 相同，並保留有效 profile、certificate、entitlements、App ID／group、DR 檢查；通過才固定安裝到本 run 的 `current/PATStorageProbe.app`。身分、argv 與原始 build logs 只留私有 root。
3. 依序 `run --root "$RIVET_PAT_RUN" --phase save-a --human-ready`、`read-a`、`replace-b`、`read-b`；每段完成即 `observe --root "$RIVET_PAT_RUN" --phase <phase> --prompts <實際次數> --whole-stage-observed`。未完整觀察不得填零；未知可省略 count／完整觀察旗標，後段會拒絕。
4. Human 就緒後 `build ... --variant rebuilt --human-ready`，另有真正 clean/build，核對 PAT host 自身相同 certificate／profile／App ID／group／DR 與不同 binary，再 `run ... --phase rebuilt-read-b --human-ready` 並 observe。建置／簽章提示另行紀錄，不能混入 runtime 次數。
5. `run ... --phase cleanup --human-ready` 只清本 run exact owned PAT item，再透過正式 store load=nil。清理可在中途失敗後另段進行，但仍需 ownership、來源與身分 proof 及無殘留 host。清理提示如實記錄，不另設 UX 門檻。
6. `export --root "$RIVET_PAT_RUN" --destination "$RIVET_PAT_EVIDENCE"` 只輸出有限結果、來源／產物摘要與 Human 觀察；不輸出 group、私人路徑、token 或原始 errors。未執行段保持 notExecuted，沒有觀察保持 null／false。獨立 Reviewer 仍須判讀，export 本身不宣稱驗收通過。

Runtime 提示門檻：save A ≤1；replace B、fresh A／B、rebuilt B 各 0。Human 必須全段觀察。固定 `open -W -a`，不用 `-n` 或 raw live binary；host 收據包含本程序 PID／OS 起始時間、instance、binary 與 build variant。來源及產物改變會拒絕續行。

寫入前依序 fsync absence 與 write-attempt markers；失敗不丟棄 run／換 namespace。每次 attempt／receipt 獨占建立，不覆寫失敗歷史。若 runtime timeout，可能仍有 host，必須先確認其結束；不自動 kill、不重試原段。清理也失敗時保留完整私有 run 供受限恢復處理，不自行猜測刪除。新 helper 的 signed/live 路徑目前未實測；unsigned compile／fakes 不證明簽章或 DPK 可用。

## 選擇性採用

由 E015 選取 public adapter 接線、真正新程序／重建、absence→write-attempt ownership 與有限 evidence 的方法；沒有複製 OAuth payload codec、登入、歷史 controller、憑證或 ready。正式 PAT query／codec 全部留在 production store；E016 只有受限驗證與 exact cleanup。

## Runner acceptance（RF-P05-01）

Host receipt 的 completed 只代表 host 結果。Runner 只有在 open 正常結束及 run／phase、binary／variant、新程序等 guards 全通過後，才 fsync 獨占發布 acceptance proof，綁定 attempt、host receipt、來源與 build proof。後續 observed gate 必須核對此 proof；Human 如實記錄提示不能把未驗證階段升格。Export 分開 hostOutcome、runnerAccepted 與整段 outcome；即使 host completed，缺有效 acceptance 仍是 unknown。原 receipt／失敗 attempt 不覆寫。

## P06 前原生 preflight 相容性修正

Designated requirement 從 codesign stdout 解析，stderr 的 Executable 僅為診斷。Profile 可用 exact 或唯一末尾 `.*` prefix 授權一個具體 group；signed app 本身仍須只宣告單一明確非 wildcard group。Signed／profile 兩端 application identifier 支援 canonical／fallback keys，缺值、衝突、wildcard 或不符 E016 固定身分均拒絕。獨立 29 tests 與 bounded review approved 只證明工具回修，不代表任何真 profile／DPK 驗收已通過。

## Managed profile 的明確建置模式

`--signing-style automatic` 是本題既有 cached assets 的受限建置選項，不授權新增或更新 Apple assets。CLI 的通用 `Apple Development` selector 不取代私人 selected certificate SHA-1；產物若選錯 Team／profile／certificate，postguard 在安裝或產生成功 proof 前拒絕。Rebuilt 仍須與原 identity 完全一致且 binary 不同。新的工具來源必須另建來源凍結 round，等當段 Human 就緒，不改寫或重試先前失敗 run。此選項的離線測試不表示正式簽章／DPK 驗收通過。
