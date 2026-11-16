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

## Xcode-managed profile 正式建置相容修補

正式 setup 的 private log 唯讀分類確證既有 Xcode-managed profile 被 manual signing settings 拒絕。原 run 保留 unknown 與 Human 全程 0 次提示，未有 App Run／PAT DPK 寫入。

Implementer 新增明確 manual／automatic 簽章選項（manual 預設），Automatic 不加 provisioning 更新旗標，只使用既有 cached assets。新產物在 copy／current／identity／build proof 之前強制 pin selected Team、profile Name、certificate SHA1；通用 Apple Development selector 不取代實際 pin。Rebuild 完整 identity 與 binary 差異仍保留。

獨立 Tester 親跑 37 tests／exit 0，非法 CLI style exit 2，來源 hashes 與交接一致。Reviewer 最終 approved，required fixes 0。新正式建置必須凍結新來源、另建新 round 並取得當段 Human ready；不能改原 run 的 source proof 或把失敗改成成功。此審查不代表新模式 native build、P06 或真 DPK 已通過。
