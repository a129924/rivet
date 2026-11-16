# E016 — PAT DPK 儲存驗證

本 host 只屬於 `github-pat-dpk-storage`，一般 `import GitHubIntegration` 直接使用正式 `GitHubPATDataProtectionStore`。沒有登入、網路、真 PAT 輸入或產品 delete；刪除只在 owned cleanup 使用精確 group／service／`pat` account。Root package 不反向依賴 E016。

## 目前真人驗收結果

受測來源 `5465d3c7308e74bc2b3b51878acd190d4f2babda`、run `39c22b57-de4f-463c-aa4b-8de277c1f60a`，在指定有效簽章環境完成正式 adapter 的 A 保存→fresh A→整筆 B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact-owned cleanup／正式 load=nil。六個 runtime 均 accepted、Human 各全程觀察 0 提示；setup／rebuild 另各 0。Rebuilt 為不同 binary，實際 `-DPAT_STORAGE_REBUILT` 生效，full identity 保持。

原 source `55aa57a` namespace 另經新 readonly recovery 正式 load=nil、accepted／Human 0；原 read A／cleanup unknown 不升格，source `0b0692e` setup unknown 保留。見[真人紀錄](../../../plan/github-pat-dpk-storage/evidence/live-validation.md)、[公開結果](../../../plan/github-pat-dpk-storage/evidence/live-run-39c22b57.json)及[獨立 P07 approved](../../../plan/github-pat-dpk-storage/evidence/live-review.md)。本次 metadata 更新不改受測 code freeze。

圖的 Human 視覺與 topic 最終接受仍 pending，不表示所有簽章環境、profile renewal／certificate rotation、公開分發、斷電 durability 或遠端登入通過。不繼承 E015 的窗口、ready、真人結果或歷史項目清理權限；E007 renewal 限制保持。

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

## 後續操作契約（每次仍須 Human 在場）

以下是保留的操作說明；本次已執行結果只以上節固定來源／run 證據為準，**不授權自動重跑或新 round**。每段由 Human 明確表示就緒後才帶 `--human-ready`；前段程序未結束、來源／身分不明、unknown 或提示超標時停止依賴段。不可沿用舊 ready。

1. 用已存在的有效私有 access group，在 repository 外的私有父目錄執行 `prepare --repo "$RIVET_PAT_REPO" --parent "$RIVET_PAT_PARENT" --access-group "$RIVET_PAT_GROUP"`。產生唯一 0700 run root；其中 JSON 為 0600，不提交私人目錄。
2. 在私有 0600 settings JSON 指定已選的 `team`、`identity`、`profile` 三欄：`identity` 必須是已選 certificate 的 40 位十六進位 SHA-1（大小寫皆可），`profile` 是已選 profile 的 Name，不填通用 identity 名稱。不得建立／更新 Apple assets，不使用 provisioning updates。`build --root "$RIVET_PAT_RUN" --variant debug --settings "$RIVET_PAT_SETTINGS" --human-ready` 預設 `--signing-style manual`，將選定 SHA-1／profile Name 作 manual build settings。需要相容已存在的 Xcode-managed profile 時，明確加 `--signing-style automatic`；只重用已快取資產，帶 Automatic／Apple Development 並清空 profile specifier，不帶 provisioning updates／device registration。缺資產就失敗，不下載、不建立新 certificate／profile、不自動重試。兩模式在 copy 到 current、發布 identity 或 build proof 前，都核新 built app 的 Team、profile Name、certificate SHA-1 與三欄 pin 相同，並保留有效 profile、certificate、entitlements、App ID／group、DR 檢查；通過才固定安裝到本 run 的 `current/PATStorageProbe.app`。身分、argv 與原始 build logs 只留私有 root。
3. 依序 `run --root "$RIVET_PAT_RUN" --phase save-a --human-ready`、`read-a`、`replace-b`、`read-b`；每段完成即 `observe --root "$RIVET_PAT_RUN" --phase <phase> --prompts <實際次數> --whole-stage-observed`。未完整觀察不得填零；未知可省略 count／完整觀察旗標，後段會拒絕。
4. Human 就緒後 `build ... --variant rebuilt --human-ready`，另有真正 clean/build，核對 PAT host 自身相同 certificate／profile／App ID／group／DR 與不同 binary，再 `run ... --phase rebuilt-read-b --human-ready` 並 observe。建置／簽章提示另行紀錄，不能混入 runtime 次數。
5. `run ... --phase cleanup --human-ready` 只清本 run exact owned PAT item，再透過正式 store load=nil。清理可在中途失敗後另段進行，但仍需 ownership、來源與身分 proof 及無殘留 host。清理提示如實記錄，不另設 UX 門檻。
6. `export --root "$RIVET_PAT_RUN" --destination "$RIVET_PAT_EVIDENCE"` 只輸出有限結果、來源／產物摘要與 Human 觀察；不輸出 group、私人路徑、token 或原始 errors。未執行段保持 notExecuted，沒有觀察保持 null／false。獨立 Reviewer 仍須判讀，export 本身不宣稱驗收通過。

Runtime 提示門檻：save A ≤1；replace B、fresh A／B、rebuilt B 各 0。Human 必須全段觀察。固定一般 `open -a`，不用 `-W`、`-n` 或 raw live binary；仍要求 open rc=0。Runner 有界等候 secure receipt，再以正整數 PID 的 `os.kill(pid, 0)` 檢查存在（不送訊號），只接受 ESRCH／ProcessLookupError 為退出證據；EPERM／其他錯誤／timeout 不算退出。Host 收據包含本程序 PID／OS 起始時間、instance、binary 與 build variant，退出後重讀完整 guards／穩定 SHA 才發布 acceptance。來源及產物改變會拒絕續行。

寫入前依序 fsync absence 與 write-attempt markers；失敗不丟棄 run／換 namespace。每次 attempt／receipt 獨占建立，不覆寫失敗歷史。若 runtime timeout，可能仍有 host，必須先確認其結束；不自動 kill、不重試原段。清理也失敗時保留完整私有 run 供受限恢復處理，不自行猜測刪除。上節固定來源／run 已有 signed/live 證據；這不擴及其他來源或環境，unsigned compile／fakes 本身仍不證明簽章或 DPK 可用。

## 選擇性採用

由 E015 選取 public adapter 接線、真正新程序／重建、absence→write-attempt ownership 與有限 evidence 的方法；沒有複製 OAuth payload codec、登入、歷史 controller、憑證或 ready。正式 PAT query／codec 全部留在 production store；E016 只有受限驗證與 exact cleanup。

## Runner acceptance（RF-P05-01）

Host receipt 的 completed 只代表 host 結果。Runner 只有在 open 正常結束及 run／phase、binary／variant、新程序等 guards 全通過後，才 fsync 獨占發布 acceptance proof，綁定 attempt、host receipt、來源與 build proof。後續 observed gate 必須核對此 proof；Human 如實記錄提示不能把未驗證階段升格。Export 分開 hostOutcome、runnerAccepted 與整段 outcome；即使 host completed，缺有效 acceptance 仍是 unknown。原 receipt／失敗 attempt 不覆寫。

## P06 前原生 preflight 相容性修正

Designated requirement 從 codesign stdout 解析，stderr 的 Executable 僅為診斷。Profile 可用 exact 或唯一末尾 `.*` prefix 授權一個具體 group；signed app 本身仍須只宣告單一明確非 wildcard group。Signed／profile 兩端 application identifier 支援 canonical／fallback keys，缺值、衝突、wildcard 或不符 E016 固定身分均拒絕。獨立 29 tests 與 bounded review approved 只證明工具回修，不代表任何真 profile／DPK 驗收已通過。

## Managed profile 的明確建置模式

`--signing-style automatic` 是本題既有 cached assets 的受限建置選項，不授權新增或更新 Apple assets。CLI 的通用 `Apple Development` selector 不取代私人 selected certificate SHA-1；產物若選錯 Team／profile／certificate，postguard 在安裝或產生成功 proof 前拒絕。Rebuilt 仍須與原 identity 完全一致且 binary 不同。新的工具來源必須另建來源凍結 round，等當段 Human 就緒，不改寫或重試先前失敗 run。此選項的離線測試不表示正式簽章／DPK 驗收通過。

## 一般 open 與 readonly absence recovery

原 source `55aa57a` 的 read A／cleanup 因 `open -W` 等待錯誤而 unknown；即使 raw host completed／Human 全程 0 提示，原 runnerAccepted=false 與原收據仍保留，不追補為成功。新 launcher 用一般 `open -a` 加有界 receipt／程序退出 gate；收據以 O_NOFOLLOW／O_NONBLOCK 開啟並核 owner、0600、regular file 與大小，只有缺檔／JSON 尚未完整可節流重讀。PID 必須 exact int>0，不以 sleep、EPERM 或仍存在的 reused PID 當退出證據。

若原 run 已有 owned cleanup 的物理結果，另經授權只補驗缺值，可使用獨立入口：

```sh
python3 -B experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py \
  recover-absence --original-root "$RIVET_PAT_ORIGINAL_RUN" \
  --host-root "$RIVET_PAT_NEW_HOST_RUN" --human-ready
```

這需要新 source 的正式建置 host、相同 Team／group／certificate／profile／DR，以及本段 fresh Human ready。Runner 核原 run namespace、absence／write-attempt ownership，並以原 recorded commit 的 Git blobs 驗原 source hashes；不拿目前改過的 source 冒充原版本。新 host 的 context／identity／binary 也須有效。驗證完成才在原 root 下新增獨占 `recovery-<UUID>` 0700 子目錄，建立新 controller／source／immutable amendment，綁原與新 proof，保留原 run ID／namespace 並另列 recoveryID。

該子目錄只准 `verify-absence`：Swift host 在建立 LiveStore／任何 Security 操作前核 recovery traces、UUID、source purpose、amendment／controller／attempt hashes 及 ownership。普通 save／read A／replace／cleanup 在 recovery root 都拒絕；normal root 也不能冒用 verify-absence。唯一 storage 操作為正式 load==nil，不 save、不 delete；有值或 load failure 都失敗。Python normal build／run 同樣拒絕任何 recovery 痕跡。

完成後可針對回報的新 recovery root 執行 `observe --phase verify-absence ...` 與 `export ...`，提示門檻為全段 0 次。新 acceptance 綁 recoveryID／amendment，不改原 unknown／receipt／source proof；即使補驗成功，也只表示同 owned namespace 目前缺值，不能提升舊 fresh-read／cleanup unknown 或替代完整新 round 的 A／B／重建驗收。原 source55 namespace 的本次 qualified readonly recovery 已記於上節；工具修改與 offline fakes 本身不等同任何額外 native recovery，也不授權再執行。
