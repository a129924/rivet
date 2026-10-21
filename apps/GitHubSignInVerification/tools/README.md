# 單次反向 PKCE 驗證

此 Python standard-library CLI 只驗證 GitHub.com 對缺少／錯誤 verifier 的遠端拒絕。它不載入正式 GitHubIntegration、Swift App 記憶體或既有 credential，不建立連線或執行 API／refresh／401。正式產品登入 UI 未交付。

正常登入與再次查詢已由來源 e941d88 驗證，本工具不重做 positive。E002 沒有 missing case，且其 generic bad_verification_code 判準不能沿用；本工具保留該結果為「無法判定」。

## 前置與操作

使用 macOS、可用的 Python 3 與本機互動 TTY。在原 feature worktree 終端執行；不用 agent exec session、管線、檔案、環境變數或命令參數傳入配置。不加 tee／log capture，不截圖配置或瀏覽器回呼。兩個案例由 Human 各自隱藏輸入與先前正向相同的 client ID／secret；callback 配置沿用 127.0.0.1/oauth/callback，當次port由系統分配。工具不自行改外部OAuth App設定。

先執行 missing，完成後只回報安全 JSON 分類，等下一步再執行 wrong：

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case missing
```

```sh
python3 -B apps/GitHubSignInVerification/tools/pkce_negative_probe.py --case wrong
```

每次 process 只產生一個新 state／verifier／S256 challenge 並開啟一次瀏覽器授權，接收新 code 後只送一次 token POST。不重用 code、不 retry、不先 positive、沒有自動接續另一案例。本輪授權上限為兩次，各 case 一次；中止或結果不明不自動第三次。若某 case 已送出，即使失敗也不能重用該 code。

Client ID／Secret 皆 getpass 隱藏輸入，無TTY直接安全結束。按 Ctrl-C 可中止。所有嘗試資料只在記憶體，沒有寫檔／log／traceback；不聲稱 Python immutable strings 可安全抹除，也不控制使用者瀏覽器／OS自身的既有留痕。回呼頁只顯示靜態提示，不echo URL；請回終端，不要複製 callback。

missing 完全省略 code_verifier 欄位；wrong 送另一個43字元base64url verifier，先確認其challenge與授權challenge不同。其餘固定HTTPS endpoint、offline_access、同次redirect、headers與form encoding保持相同。callback先ready後開瀏覽器，限定127.0.0.1、GET、exact Host/path/state及單次claim；8KiB headers、每連線5秒、最多16connections、授權到POST總5分鐘。POST完整I/O硬性上限為剩餘授權期限或30秒較小者，response上限64KiB；無redirect、proxy env、cookie、cache或retry。

## 事前固定判準

- `passed`：HTTP2xx或400、純error無任何token／成功payload，error精確為 missing_code_verifier、incorrect_code_verifier、invalid_code_verifier、code_verifier_required。這是保守辨識allowlist，不宣稱GitHub官方保證error名稱。自由文字description不參與通過判定。
- `failed`：JSON object存在access_token或refresh_token key，包含空值、混合error與異常type；不使用、不保存回應token。
- `indeterminate`：一般bad_verification_code、配置／redirect／email錯誤、拒絕授權、expired／timeout／network、unknown／shape／HTTP異常等。remote_rejected=true只代表收到error，不代表PKCE通過。

stdout只輸出固定提示與安全JSON：case、outcome、reason、有限remote_error、HTTP整數及必要布林。未知error映射unknown，沒有clientID、secret、code、state、verifier、token、body、URL或exception文字。退出碼passed=0、failed=1、indeterminate=2；不能單憑非零就當PKCE enforcement通過。

來源：[GitHub授權契約](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)、[token錯誤說明](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)。bad_verification_code亦可能指code錯誤或過期，所以不可專指PKCE。

## 受控測試

```sh
python3 -B -m unittest discover -s apps/GitHubSignInVerification/tools -p 'test_pkce_negative_probe.py'
```

只有fixture與本機loopback，沒有真OAuth、秘密或GitHub呼叫。-B避免產生__pycache__；不安裝依賴、不改工具設定。遠端證據見topic `evidence/pkce-negative-verification.md`，不得把mock green當成真實passed。
