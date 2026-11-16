# 一般 open／只讀 recovery：獨立審查

2026-11-16，Reviewer `/root/planner`。方向依本機 open(1)／kill(2) 文件判讀屬既有 bounded wait／recovery 契約；不新增 E017，不重開產品／架構決策。

初次 static finding：receipt open 若遇 FIFO 可阻塞在 fstat 前，越過 deadline。Implementer 加 O_NONBLOCK，補真 scratch FIFO 立即拒絕、zero kill／zero acceptance 回歸。

最終 Reviewer 已讀實際來源與獨立 Tester 證據：Python 54 tests／exit 0；Debug／Rebuilt unsigned builds 成功，各 113 fake checks 通過；三份來源 hash 一致。O_NONBLOCK、secure receipt／退出 gate、Swift pre-Security recovery admission、只讀 load=nil、amendment／recoveryID 綁定及原 proof 保留均符合契約。

Verdict：approved；FIFO finding closed；required fixes 0。舊 signed binary 的一次 normal-open fake smoke 只支持 transport，不代表新 runtime。新 source 正式建置、原 namespace 只讀 absence recovery、新完整 round 與 Human 觀察仍待當段 fresh ready；原 source55的unknown／觀察均不得改判。
