# E016 path identity：獨立離線重驗

日期：2026-11-16。Tester只執行純Foundation小程式與本機mock checks；沒有建置主App、sign、launch、DPK、preflight、新run或budget重試。舊signed App／consumed marker／收據未修改。

## 親跑結果

- `python3 -B -m unittest discover -s experiments/E016/Tests -p 'test_*.py'`：exit0，20 tests，0.026秒。
- 依COMMANDS.md以新私有暫存輸出，用`swiftc`編譯`Sources/E016PathIdentity.swift`與`Tests/path_identity_checks.swift`，執行結果exit0：alias及distinct-object checks passed。這是實際host共用helper，非另寫policy toy。
- 三個Swift檔的`swift format lint --strict`及`swiftlint lint --strict --quiet`：exit0。
- `git diff --check`：exit0。
- `git diff --quiet HEAD -- Sources Tests Package.swift Package.resolved packages/RivetHTTPClient`：exit0；正式程式零差異。

## 有區辨力的範圍

Foundation helper雙側normalize/resolvingSymlinks，並檢查filesystem device/inode。實際離線檔案證明tmp/private tmp兩種alias的bundle/executable同物件可接受；不同App及同內容不同executable拒絕。主App原始碼確認bundle/executable guard與hello.path實際採用該共用helper。

Python mock直接呼叫實際launch_phase，完整走hello→actual process→authorize→machine→terminated/private projection；alias正例明確有authorize，different object及actual process不同物件負例明確沒有authorize。hello PID／binary hash與source/profile/transition/stopped guards仍存在。這些是fake subprocess／fake process資料，不能證明新主App已正常啟動或真PID／DPK成功。

## 公開停點projection核對

`experiments/E016/evidence/first-stop-summary.json`使用獨立`e016.stop-summary.v1` schema，不是不存在的協定`first-public.json`。

Tester唯讀對照舊run：machine SHA相符；first-consumed存在；hello、authorize與協定public仍不存在。projection的exact_process_exit_proven=false、protocol_public_receipt_available=false及unique_runtime_cause_proven=false如實，不把path policy bug當成當次唯一根因。

私有first-human-observation檔SHA與公開human_observation_hash相符；其bound_receipt_kind=machine、bound_receipt_sha256與first machine SHA相符，phase一致、observation_complete=true，prompt class=zero。這只是Human attestation的綁定核對，不是Tester自己看見提示，也不補出缺失的exact PID/starttime或publicreceipt。

## 停點

原first budget維持已消耗；fresh未執行，結果仍indeterminate。離線修正不恢復額度，不允許重試或改namespace。最終harness correctness及是否需新Human決策交獨立Reviewer；本Tester不自評approval。
