# DPK 實驗受限技術規格

> 2026-10-16 原始準備契約；最新執行結果見 [E006 README](../../experiments/E006/README.md)／[step](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.step.md)。

本規格是 E006 實驗設計，非正式 credential adapter；目前只授權準備與 unsigned／mock 驗證。需求見 [requirements](requirements.md)。

## 固定 host 與資料

獨立 `experiments/E006/DPKProbe.xcodeproj`、單一 `DPKProbe` macOS Application target，AppKit main／NSApplication GUI；main executable 直接執行 Security 呼叫，不用 CLI/helper。來源放 `Sources/DPKProbe/`，不依賴 root package，不宣告 public API，不修改 provider。最小視窗只顯示階段與完成／錯誤，不顯示 token 或提供手動跳關按鈕。

實驗 namespace 為 UUID；bundle identifier 使用 `local.rivet.dpkprobe.<去連字號 UUID>`，同一輪固定。安裝到本輪私有 scratch 的同一 `DPKProbe.app` 路徑，兩版不得並行存在於該路徑或同時啟動。未來真測經 LaunchServices `open -n ... --args ...` 正常啟動，不直接執行 Mach-O。App 必須在目前非 root 使用者已登入的 GUI／security session；root、launch daemon、無登入 session 均拒絕。

免費 Personal Team、automatic signing、Apple Development、embedded development profile。啟用 Keychain Sharing capability，entitlements 僅一 group：`$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`。由 Xcode 解析，不手填 Team ID；解析 group 等於 `com.apple.application-identifier`。profile 的 exact 或 wildcard 授權須覆蓋該 group，不要求字串相等，不跨 App 共用。未簽建置使用 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`，不設個人 Team、不 provisioning、不啟動 App。

六欄名稱沿用 E005：accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes；固定假 A 及固定時間，JSON Codable 單筆 payload。以來源引用記錄 E005 比較邏輯，複製必要實驗邏輯而不改 E005。僅 generic-password、UUID service/account、唯一 group；add/query/delete 明指定 DPK true、synchronizable false。add 使用 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`，無 user-presence／biometry access control，不設 ACL／partition、不 fallback。不測 B／refresh／其他 identity。

## 準備與真實執行隔離

`scripts/prepare.py` 只產生本輪未簽 project 配置／兩版 build marker 與 unsigned build 指令；不選 account、不簽章、不預設自動 provisioning。`scripts/preflight.py` 分純解析模式與明確的未來 `--live` 模式；目前只可測 fixture／mock，live 必須另有 Human 開發資產操作授權。live 僅檢查 Human 已選 App／profile／certificate，不盤點其他身分，不建立資產。

live proof 核對免費來源 Human 聲明、certificate chain／有效期、profile 授權／本機適用性、codesign validity／entitlements、DR 雙向滿足、GUI session。profile/certificate 均須覆蓋測量起點至少 35 分鐘。兩版 certificate、embedded profile bytes、entitlements、bundle/path/DR 相同，main executable SHA-256 不同且只有 marker 改變。測量中不重新佈建。缺任一項零 OAuth write，unknown 停止。

`Sources/DPKProbe/LiveStore.swift` 是唯一 SecItem 呼叫入口，與純 `ProbeCore`／fixture 比較隔離。未取得 live proof、namespace／binary／phase 比對及 Human gate 前不能建構 live store 或呼叫 Security；不以任意 `--live` flag 取代 proof。mock 使用獨立 injected in-memory backend，收據標 `synthetic=true`，不把 mock proof 接到 live；proof 是本機協作門檻而非抵抗惡意本機使用者的安全邊界。

## 檔案與階段協定

`scripts/run_probe.py` 為唯一 coordinator；`scripts/ux_stages.py` 處理 gate／receipt／deadline。私有 scratch 為使用者擁有的臨時根目錄下新建 UUID 目錄（0700），不是任意使用者檔案路徑；拒絕 symlink／非本輪子路徑。輸入固定為該目錄 `window.json`、`run.json`、`preflight.json`、`control/gate-N.json`；輸出 `receipts/phase-N.machine.json`／`phase-N.human.json`，exclusive create、不覆寫。App argv 只接 scratch 路徑／namespace／phase／operation，不接 token。receipt 公開版只留檔名／hash／布林授權核對，不輸出本機絕對路徑、Team ID、certificate subject、device ID 或 credential 值。完整 identifiers 僅私有 proof 使用，清理後不提交。Human 的 Xcode 開發資產操作必須使用外部私有 scratch 的 project 副本或外部設定；不把個人 DEVELOPMENT_TEAM／account 識別回寫可提交 feature template，本 template 保持無 Team。

Human 未來明確資產設定 ready 後、第一筆帳號／資產設定前，先用 `run_probe.py --begin-window` 的獨立 bookkeeping mode 在新私有 scratch exclusive 保存同 namespace `window.json`／t0／cutoff=t0+25min／deadline=t0+30min；此 mode 不 inspect、簽章、launch 或 SecItem。namespace 必須與稍後的 bundle identifier／selection 一致。後續 coordinator／preflight 僅讀此記錄，不使用 coordinator 開始時間或 selection 自訂時間重設。缺記錄、錯 namespace、future／cutoff／expired 起點在 inspect／launch 前拒絕；原始 window SHA 綁 proof／run manifest，改動即停止。run manifest 包含 UUID、human-only、原 t0／25min cutoff／30min deadline、window SHA、兩版 hash、proof SHA、候選固定 DPK 及 service/account。proof 必須 live 且重新核對實際 App hashes／期限，不接受 mock；App 每次啟動再次核對當前 executable／namespace／phase／proof。若環境或 assets 改變，停止，不重簽續跑。

phase 0 保存前提 machine receipt，不讀寫 OAuth；Human setup 觀察與 phase 1 ready 綁其 SHA。phase 1 `save-read-a`；phase 2 第一版 `read-a`；phase 3 用真正重建第二版 `read-a`；phase 4 `delete-read-absent`。每個 App process 完成一次操作即寫 machine receipt並退出；coordinator 確認退出才啟動下一個，phase 2/3 不能改寫 A。兩版在真測前完成並核對，phase 3 將第二版替換到同一路徑後讀取，仍記實際 hash。

gate 必須有 namespace、phase、observationMode=human-only、previous machine SHA、明確 Human ready／時間；Human observation 必須有 matching machine SHA、wholeStageObserved=true、phaseIdentified=true、整數 promptCount≥0、actions／purposes 與次數一致（零為空陣列）。前段 receipt 要重新 hash，不只信欄位。任何缺漏禁止下一段；desktopConnected 不宣稱 true，提示不得從 exit code／耗時推論。Human 檔由 agent 僅依實際回報建立，不預填未觀察結果。

machine receipt 含 UTC 起訖／namespace／phase／mode／synthetic／實際 executable SHA／proof SHA／六欄 equality／有限 OSStatus 或錯誤分類／清理結果，不含 payload。完整觀察與新 ready 是正常下一段必需；不得任意重跑。

## 截止、清理與失敗

單輪從第一筆 Human 帳號／資產設定前保存的 t0 起共 30 分鐘，25 分鐘停止新測量；unsigned build／mock／圖工具在窗口外，Human 登入／資產建立／簽章建置均計入同窗口，不重新 arm 或延長。profile CreationDate 與 selected certificate chain 的當下有效性（含 NotBefore）依實際 preflight now 驗證，允許在 t0 後建立；profile／certificate 到期餘裕仍須覆蓋原 t0+35min。cleanup 不重設 t0，即使過 deadline 也只允許原 namespace 的清理／recovery。setup 及清理設定授權與 credential prompt 分開。abort、deadline、缺觀察、訊號或任何失敗直接 finally 精確清理，不等下一段／phase 4 ready。清理使用已核對的實驗 App 與完全相同 DPK group/service/account；只允許 delete＋read-absent，不因逾時允許新 save/read 測量。不完整 proof 且從未寫入時記 not-attempted；若曾可能寫入則清理必須有證據。

需要系統授權仍由 Human 完成，未完成明列殘留與人工復原，不宣稱 clean。未確認項目不存在時保留必要已簽 App／最小 recovery 資訊供 Human，不先刪至無法復原。不可捕捉強制停止／主機失效不保證 finally；保留 recovery 說明。成功清理刪除 App／私有 proof／暫存，保留去識別化 machine/Human 證據。Apple developer assets 不刪除，逐項標示 Human-owned 保留，不能冒稱所有資產清除。

## 測試與來源

純測試用 `Tests/` 與 mock process/clock/store，不載入 Security、不啟動 App。測 unsigned compile/typecheck；真簽章／profile／GUI／SecItem／prompt 案例保持未執行直到 Human 邊界解除。詳細驗收與工具契約見 [plan](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.plan.md)。官方依據列於 requirements；DPK eligibility、免費來源與七日續期不可由 unsigned build 成功外推。
