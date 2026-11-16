# E016 獨立 unsigned 驗證（2026-11-16）

Tester 只執行本機 fake checks、unsigned build 與靜態檢查；未簽章、未啟動 host、未 seed/delete、未存取真 DPK、未建立 live run UUID 或消耗 live 額度。本文件不構成 harness approval 或 T09 成功。

## 親跑環境與命令

基線 HEAD：`708cf6053a5a557d7d482351a7489f2363e2d406`；受測為該 feature worktree 當時尚未提交的 E016 bounded diff。Xcode26.6（17F113）、Apple Swift6.3.3、Python3.14.0。

- `python3 -B -m unittest discover -s experiments/E016/Tests -p 'test_*.py'`：exit0，7 tests／0.001秒。
- 依 COMMANDS.md 以新 owner-only private DerivedData 呼叫 `build_unsigned(...)`：exit0，建置log含 BUILD SUCCEEDED；helper完成前後 source manifest 相等檢查並建立 companion。無簽章、沒有 App launch。
- `swift format lint --strict experiments/E016/Sources/main.swift`：exit0。
- `swiftlint lint --strict --quiet experiments/E016/Sources/main.swift`：exit0。
- `git diff --check`：exit0。
- `git diff --quiet HEAD -- Sources Tests Package.swift Package.resolved packages/RivetHTTPClient`：exit0，正式 source／tests／package 與本topic已提交HEAD零diff。

## 安全 provenance

私有 build-source companion 保存實際命令對應source manifest、commit、dirty狀態及90個source／package／host／resources／project／runner檔案hash。原始log與私有絕對路徑留系統暫存，不公開。

- build-source companion SHA-256：`4c3f6960186904e21401fe5bcbc10506a138dbb923258326430a2790353081f3`
- unsigned binary SHA-256：`2cd98237dc462ea458c8a0dfb4231909372c3233b225194fb90d419fb2ddf71c`
- build log SHA-256：`f4c160af4c3d28311e2a804b165197ea55dec34a3b313fa17b25237b76017bc9`

companion凍結後任何來源／commit／dirty狀態改變均使該build不適用後續preflight。此後寫入本文件也會改變dirty manifest，因此這個Tester build只作unsigned先驗證據，不是後續live可直接使用的frozen build。

## 七個 fake checks 的實際證據範圍

| 檢查 | 已測 | 未測 |
| --- | --- | --- |
| absence | Python seed_allowed 的三個布林輸入與三種存在情況 | Swift first 的真讀取／save前拒絕路徑，Python helper未接Swift |
| fresh policy | allowed_operations(fresh)回傳load且無clear | helper未由runner或Swift呼叫；未執行Swift fresh分支或mock store write監測 |
| redaction | public_receipt拒絕五個指定未知keys | 未測完整machine→private→public管線、全部允許欄位型別／required集合與任意錯誤路徑 |
| one-shot | 同一tmp root的consume(first)第二次拒絕 | 未mock launch_phase的launch前消耗／中斷流程、fresh二次或狀態轉移 |
| provenance | require_equal對兩字串不相等拒絕 | 未測source_manifest/sourcefreeze變更的負向輸入、signed_info/profile/cert／launch provenance整合 |
| process | require_process的pid/path/hash同時不符拒絕 | 未測各欄位單獨不符、process_info/starttime/stopped/actual executable握手整合 |
| prompt | unknown經public_receipt保持unknown | 未測Human attestation與machine receipt hash綁定或fresh之前的attestation gate |

實際unsigned build已執行sourcefreeze happy path，但沒有刻意改source的negative試驗。以上7通過不能擴稱整runner協定已由fake tests驗證。

## 交獨立 Reviewer 的限制

- Swift fresh branch 原始碼位於first條件之外的讀取檢查，靜態上未見save/delete，但尚無mock adapter執行驗證；不可把未使用的Python policy helper當成Swift write隔離證明。
- launch_phase(fresh)檢查first machine passed／frozen hash／terminated與exact process已退出，但沒有機器檢查first Human attestation檔；COMMANDS.md要求主session在fresh前完成該步。此為流程依賴，交Reviewer判斷是否需工具gate。
- 簽章、embedded profile/cert/exactgroup／expiry、actual PID/starttime/path/binary握手、兩程序退出與真DPK結果全部未執行；不能稱signed ready。
- sourcefreeze build已成功不等於其所有負向守衛已驗證；live額度與原本T09判準保持不變。

Tester任務完成：unsigned先驗結果與缺口已如實保存，明示交Reviewer，不作approval。T09實驗狀態仍為未執行。

## 回修後獨立驗證（2026-11-16）

本輪只重驗Python runner／tests及必要靜態檢查；Swift host沒有改動，不重建全build。Tester未執行actual sign／launch／DPK。

- 親跑相同unittest discover命令：exit0，16tests／0.022秒。
- Swift format／focused lint、Python兩檔ast.parse、git diff --check：exit0。
- root Sources／Tests／Package.swift／Package.resolved／RivetHTTPClient對HEAD仍zero-diff。

### Required-fix場景的證據範圍

1. build→sign鏈：replaced_unsigned_build_never_signs直接呼叫實際sign_prepared，替換binary後驗command未被呼叫且無signing receipt。sign_records_checked_unsigned_to_signed_transition直接呼叫sign_prepared（command／signed_info mock），再用實際verify_transition核簽前unsigned hash／build-source hash、簽後binary／bundle／profile；changed signed hash/source拒絕。preflight_requires_signing_chain直接呼叫實際preflight，缺鏈不建立runroot；changed_signing_transition_never_launches直接呼叫實際launch_phase，transition hash不符不Popen。這些已接actual runner path，但不等於真codesign／certificate／profile驗證已執行。

2. runner守衛：launch_consumes_before_popen_interrupt_cannot_launch_again直接呼叫實際launch_phase，mock Popen當下檢查first-consumed已存在，再模擬中斷；第二次Popen未發生（總call_count=1）。source／signed binary mismatch在launch前拒絕；actual process path／hello binary mismatch在authorize前拒絕。fresh缺first receipt、failed first、terminated false、actual process未退出、frozen provenance不符均透過實際launch_phase測得不Popen。

以上補足前輪純helper測試未接實際runner之缺口。仍未測Swift host fresh的mock store write監測、完整成功launch→machine→public管線、實際簽章／PID/starttime取得或DPK；相關靜態分支與live前提交Reviewer審查。Human attestation仍由主session於兩階段間完成，工具不自動核對。

本次source/runner已變更，前輪unsigned companion不再適用live；最終freeze應在審查後重建。獨立重驗結果明示交Reviewer，不自評required fixes closed或approval。T09維持未執行。
