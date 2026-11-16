# P06 前工具回修：獨立審查

2026-11-16，獨立 Reviewer `/root/planner`。初次 preflight review needs-rework，限 E016 runner：DR 讀錯串流、profile group 授權比較過窄，以及 App ID 缺值相等／fallback 缺口。

Implementer 以 TDD 回修，獨立 Tester 親跑最終 29 tests／exit 0，兩來源 SHA 與 profile-claims-tests 一致。Reviewer 再讀實際 diff 與四份交接／補驗證據，最終 verdict：approved；三 finding 均 closed，required fixes：0。

- DR 讀 stdout，原生系統 binary 觀察及 Tester 補驗支持；stderr Executable 不作 requirement。
- Profile exact／唯一末尾 .* matching prefix 授權，signed app 仍限制單一明確 group。
- Canonical／fallback App ID、雙 key 一致性、缺／空／非字串／wildcard／錯 ID 拒絕，兩端對應 E016 指定身分。

可凍結並提交 bounded 工具 fix；不代表實際準備 App、正式簽章 preflight、真 DPK、Human 提示、cleanup 或 P06 已完成。

## 公開憑證擷取 argv 回修收斂

新的 exact-artifact 唯讀診斷在公開憑證擷取 rc=1 停止；此前 claims／profile 檢查通過。原 unknown 保留，不追補原次根因。依 E015 既有實作改採單一 `--extract-certificates=<prefix>`，新增真實 argv shape 回歸。獨立 Tester 30 tests／exit 0，來源 SHA 相符；Reviewer 再審 finding closed、bounded approved，required fixes 0。

工具修正核准不代替新 exact-app native inspect 或正式 P06。Tester 另一次新授權唯讀查核已通過並私下保存設定，見 live-preflight；正式固定位置建置、runtime、Human 提示與 cleanup 仍未開始。
