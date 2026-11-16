# E016 有限準備與操作

本文件命令是可審查入口；unsigned／fake checks 之外，尚未執行。不得把建置成功當作 live ready。所有命令從 feature worktree 根目錄執行；shell 變數僅指 E016 專用私有輸出，不能指向舊 App／舊 run root。

## 無簽章建置與 fake checks

```sh
python3 -B -m unittest discover -s experiments/E016/Tests -p 'test_*.py'
```

獨立建置使用 Xcode `E016LogoutProbe` scheme、Debug、`CODE_SIGNING_ALLOWED=NO`。以下 preparation helper 在建置前後比對來源、保存 build log hash／unsigned binary hash 與逐檔 source manifest；沒有簽章、啟動或 Keychain 操作。

```sh
E016_BUILD_DIR="$(mktemp -d -t rivet-e016-build)"
chmod 700 "$E016_BUILD_DIR"
export E016_BUILD_DIR
python3 -B - <<'PY'
import importlib.util
import os
spec = importlib.util.spec_from_file_location('e016', 'experiments/E016/scripts/e016_live.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.build_unsigned(os.environ['E016_BUILD_DIR'])
PY
E016_APP="$E016_BUILD_DIR/Build/Products/Debug/E016LogoutProbe.app"
```

不得編輯 build-source companion；來源／commit 改變即停止使用該 build，回準備／獨立審查，不在 first/fresh 間 rebuild。建置執行的是 root public GitHubIntegration，不是 E015 副本。

## 審查後的 manual signing 準備（未執行）

先把既有 exact profile 私有實際路徑指定給 `E016_PROFILE`；主 session 核對 profile UUID／SHA、expiry、identity 與憑證後才可使用。這不是新資產操作。`E016_GROUP` 為 technical-spec 鎖定的唯一 exact group；不使用 wildcard。

```sh
export E016_PROFILE E016_APP
python3 -B - <<'PYCODE'
import importlib.util
import os
from pathlib import Path
spec = importlib.util.spec_from_file_location('e016', 'experiments/E016/scripts/e016_live.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.sign_prepared(Path(os.environ['E016_APP']), Path(os.environ['E016_PROFILE']))
PYCODE
```

此 helper 在 codesign 前強制比對 source、build-source companion 與實際 unsigned binary hash；不符就不簽。成功簽章後驗固定 profile／actual cert／entitlements，記錄唯一 unsigned→signed 轉換的 signed binary／bundle／profile hashes。preflight 與兩段 launch 都驗此鏈；不接受繞過 helper 的手動簽章、替換 build 或修改 companion。簽章嘗試失敗保留 marker，不自行重試。

不使用 automatic provisioning、deep signing、新 profile、trust／ACL 修改。若 unsigned App 含需單獨簽章的 nested code，先停止交 Reviewer，不臨場增加 signing 動作。

## Preflight 與唯一兩程序（未執行）

先建立 owner-only 私有 parent，`E016_RUN_ROOT` 本身必須不存在。preflight 只讀簽章與環境，建立新 E016 UUID／frozen provenance；不碰 DPK。簽章/profile/來源不符時停止，工具只輸出有限錯誤提示。

```sh
E016_RUN_PARENT="$(mktemp -d -t rivet-e016-run)"
chmod 700 "$E016_RUN_PARENT"
E016_RUN_ROOT="$E016_RUN_PARENT/only-run"
python3 -B experiments/E016/scripts/e016_live.py preflight --app "$E016_APP" --run-root "$E016_RUN_ROOT"
```

主 session 必須在命令與 freeze 經 Reviewer 檢查後，安排 Human 每段從啟動至 exact process 結束的完整提示觀察，再分別執行：

```sh
python3 -B experiments/E016/scripts/e016_live.py first --app "$E016_APP" --run-root "$E016_RUN_ROOT"
# 確認 first 通過且 exact process 退出，完成第一段 Human attestation 後才進 fresh。
python3 -B experiments/E016/scripts/e016_live.py fresh --app "$E016_APP" --run-root "$E016_RUN_ROOT"
```

first 消耗標記在 bundle launch 前寫入；即使中斷也不得重試或換 root／UUID。fresh 需 first machine passed 與 exact process 已退出，且同 binary/profile/source。App 在 runner 驗 actual PID/starttime/path/hash 並授權前，不做 DPK。fresh 沒有任何 seed/save/delete 分支。

各階段 machine/private/public receipts 寫入 run root；private 包含 path/PID/starttime，公開 projection 僅 allowlist。Human attestation 由主 session 在私有檔中手動保存實際 prompt count／observation_complete 與該段 `*-public.json` 的 SHA-256；缺完整觀察就保持 unknown，不得補0。公開時僅 `zero/nonzero/unknown`、完成布林與 attestation hash，不公布數字、路徑、身份或 fixture。configuration／sentinel 保留，無 cleanup 命令。
