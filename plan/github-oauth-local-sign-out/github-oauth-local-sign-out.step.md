# 本地登出與 OAuth 憑證清除：狀態帳本

- Topic：github-oauth-local-sign-out
- Phase：T09 有限實驗完成／Reviewer approved；文件一致性審查與 S06 Human review 待辦
- 基線：2973150b2789d63c10226b57150073ccc793c509
- Branch：feat/github-oauth-local-sign-out
- 最後更新：2026-11-16 Asia/Taipei（bb6752a 有限系統驗證完成，僅同步文件）
- 現行上游：Reviewer 已獨立核對 bb6752a 兩程序／原始收據／Human attestation，明示 approved（本次有限實驗）；不代表 Human 最終 topic 接受。

| ID | Status | Owner role | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 四份同 slug artifacts 落 feature worktree，保留九欄、API、三 tools、feasibility 與邊界 | 本次四份 artifacts；未執行實作／測試，品質由 S02 獨立審查；無自評 approval。 |
| S02 | completed | Plan-Reviewer | 四份均可讀，獨立核對需求／scope／contract／readiness | 獨立 Plan-Reviewer 明示 approved（2026-11-13），無 required fix；已核對四份及 provider／DPK／scope source。 |
| S03 | completed | Implementer | 僅依 S02 approved bounded contract 完成 src/tests/docs/必要實驗入口 | 11/13受限src／tests完成，root316tests／format／focused lint通過；當時E016未建立。T09後續完成狀態另見下表，歷史不覆寫。 |
| S04 | completed | Tester | 親跑受控／consumer回歸並如實列出 T01–T09 證據限制 | [獨立驗證](evidence/tests.md)：44 focused／316 root／15 consumer通過；回修11 sign-out tests通過，T04/T08補證；11/13當時T09未執行；後續T09另見下表，不混用兩輪證據。 |
| S05 | completed | Reviewer | 獨立核對受限 code/tests 與 required fixes | 2026-11-13 18:16 明示 approved，T04/T08 closed；不包含未建立的 E016 harness／T09。 |
| S06 | pending | Human | 最終 review／必要圖面接受／既有 commit boundary | 未開始。 |

## Blockers／目前停點

- T09本次有限實驗已成功，獨立Reviewer approved；受測commit固定bb6752aa483a68043174723a6b3ff2653abe79ce，詳[e016-live.md](evidence/e016-live.md)。
- 目前只待最終文件一致性審查與S06 Human最終topic review／必要圖面接受；不把技術approved當作Human接受。
- ff672c7舊first的無法判定與額度消耗保留；Human新增bb6752a序列first/fresh也已用完，不再執行或cleanup。
- PR發佈狀態由主session處理，本文件不新增遠端判定。Graphify／PR Lens／圖面既有證據與限制沿原記錄，不由T09實驗補成其他工具通過。

## Human Check

- 已確認：單一 owner／唯一 writer；保留 App configuration；執行已接受的 feature-worktree 計畫。
- 本次first/fresh Human皆已確認完整觀察，提示class為zero；各attestation綁原publicSHA，原unknown欄位不覆寫。
- 尚待：S06最終topic review及必要圖面視覺接受，不由本次實驗approved替代。
- Human 本輪明確授權按 topic commit、push、開 Draft PR；仍先檢查 staged semantic boundary，由主 agent 執行；最終交 Human review。
- 2026-11-13 18:20 收斂為歷史；11/16續行只補T09，不以時間上限代替完成。

## Locked decisions

API／retirement／pending-write／error／cancellation／retry 依 technical-spec；不重開。不把其他 topic 或歷史 experiments 併入此 topic。

## Artifacts

- ../../analysis/github-oauth-local-sign-out/requirements.md
- ../../analysis/github-oauth-local-sign-out/technical-spec.md
- github-oauth-local-sign-out.plan.md
- github-oauth-local-sign-out.step.md

## Implementer 交接證據

Red：新測試首次編譯因缺 OAuthCredentialClearingStore／signOut 失敗（安全暫存 log rivet-signout-red）。Green：9 sign-out tests 通過；provider／DPK 前一輪41tests通過；最後 root316tests／39suites通過。靜態allowlist已增加兩個新contract。scripts/check-swift-format.sh exit0；focused swiftlint GitHubIntegration Sources/Tests 60files 0violations；git diff --check exit0。全repo swiftlint 掃入歷史experiments有既有大量違規，不擴張回修；本次3項lint已修。

T01–T07有新增受控測試（T04/T05的原需求task可先於退休完成，驗收核心為save→clear-start→clear事件順序及後續signedOut）。T08精確selector／binding／corrupt／delete failure及scope prepare mapping已測；已持有REST／GraphQL scope的新工作與401 recovery尚無專屬新增案例，交Tester判斷必要性。T09未執行，E016缺harness及簽章前提證據；不得宣稱重啟實證。

## Reviewer required fixes 回修（2026-11-13 18:14）

T04兩個pending-save案例已在gate關閉時以snapshot回覆signedOut確認退休，並斷言clear尚未開始，再release save。握手有1秒超時開gate及失敗判準，避免測試死鎖；無production hook。T08新增真實已prepare scope的REST／GraphQL後續工作不送出，以及兩者401 response gate中登出、晚到401不refresh/retry。11個本地登出測試通過（安全暫存rivet-signout-rework.log），交Tester獨立重驗。此回修覆蓋前段T04/T08缺口，T09仍未執行。

## 最終受限成果審查（18:16）

Reviewer 明示 approved（受限 code/tests）：T04、T08 required fixes closed，無其他 required fix。Tester 最後獨立11tests/1suite與diffcheck通過。Timeout child只返回false；parent鎖定結果後才清理gate，取代前段timeout描述。S05受限審查完成，S06 Human review pending。T09/E016缺signed harness及真DPK fresh-process證據，topic完整驗收未完成。Human已明確授權本topic commit/push/Draft PR；不以此代表完整驗收或Human最終接受。

## 2026-11-16：T09 continuation

下列為11/16補充steps的現行狀態；各輪needs-rework／stopped歷史保留於後段，不回寫舊approval。既有S01–S05歷史evidence原樣保留，S06 Human最終review仍pending。

| ID | Status | Owner role | 完成條件 | 證據／verdict |
| --- | --- | --- | --- | --- |
| T09-P1 | completed | Plan-Creator | 四份artifacts及E016八段README具體化既有資產、獨立host、一次兩程序、safe receipt／停止規則 | 本次補充文件；未自評approved。 |
| T09-P2 | completed | Plan-Reviewer | 獨立審查補充契約，明示verdict | 2026-11-16 獨立Plan-Reviewer approved，無required fix。 |
| T09-I | completed | Implementer | E016 unsigned host／最小runner／fakechecks、實際命令與source freeze | 已建立並經後續bounded fixes；20mock checks與共享Foundation離線測試通過，正式Sources零diff；相關歷史見後段。 |
| T09-R1 | completed | Reviewer | 獨立審查新harness與fake evidence | provenance／實際orchestration／certificate optionalarg／path identity required fixes均已獨立approved；不沿用S05。歷史見後段及[unsigned先驗](evidence/e016-unsigned-tests.md)。 |
| T09-V1 | completed | Tester | 審查後signing preflight、frozen binary/profile及actual launch identity證據 | bb6752a全新凍結／build／manual sign／preflight完成，兩live段每次重核；source/binary/profile/transition與actual process證據見[e016-live.md](evidence/e016-live.md)。 |
| T09-H | completed | Human | 工具具體可檢視後安排兩段完整prompt觀察，attestation綁receipt hash | bb6752a first/fresh各全程觀察zero，各attestation綁原publicSHA；原machine/public bytes不覆寫；不是S06最終接受。 |
| T09-V2 | completed | Tester | 唯一first/fresh序列、判準分類／safe receipt／殘留紀錄 | Human另授權bb6752a新序列first/fresh皆passed，兩exact processes歸屬／退出及Human綁定核對完成；configuration/sentinel留存。舊ff672c7 stopped保留，不覆寫。 |
| T09-R2 | completed | Reviewer | 獨立審查系統結果與限制，回原topic | 2026-11-16明示approved（本次有限實驗）；核originalreceipts／attestations／frozen來源／兩exactprocess退出及限制，無其他required fix。 |

本句原為規劃落檔時狀態：當時沒有production修改或build/test/sign／Keychain操作。之後僅E016受限工具與明確授權live序列推進；bb6752a的實際結果／有效性重驗依上述證據，不能以早期inventory替代。

## T09-R1 needs-rework 回修交接

Reviewer要求unsigned→signed provenance鏈及實際launch_phase mock coverage兩項；Implementer已完成E016限定回修，16fakechecks通過，無真簽章／launch／DPK。COMMANDS以sign_prepared專用helper取代手動codesign繞過；preflight/launch必核轉換hash。狀態仍待Tester及Reviewer重新明示verdict，不自評approved。產出文件／review仍可改變dirtymanifest，最後sourcefreeze需最後review後重建，不沿用先前companion。

## 2026-11-16 E016 unsigned 回修審查

獨立Tester親跑16fake checks、format/lint/Python AST/diffcheck通過；production零差異。Reviewer明示approved（unsigned harness／回修），兩項required fixes closed：unsigned→signed來源轉換鏈，actual orchestration mock guards。准凍結後重建／manual signing／preflight，不代表signed ready或T09 passed。最終Human觀察與真DPK兩程序仍pending；不沿用舊build。

## 2026-11-16 簽章準備停止與 bounded fix

014bab2 的全新 unsigned build 成功；codesign 實際成功，後續 certificate extraction 因 optional argument 分離語法錯誤停止，沒有完整 signing transition receipt。未進 preflight、未啟 App、未操作 DPK；T09 仍未執行，first/fresh 額度未消耗。舊 App、attempt marker、停止收據保持不動，未重建／重簽或補造 receipt。

signed_info 已改為單一 --extract-certificates=<prefix> 參數。獨立 Tester 17fakechecks/diffcheck 通過，記憶體反向形狀驗證能拒舊寫法；Reviewer approved（bounded command fix），無其他required fix。下一停點：依 COMMANDS 的不自行重試規則等待 Human 明確續行，才可用修正版重新凍結/build/sign/preflight。此處不是 T09 passed 或 signed-ready。

## T09 唯一first停止／path identity bounded回修

2026-11-16，ff672c7準備及preflight後唯一first已消耗並在hello前停止，fresh未執行。Reviewer分類無法判定，不是production failure；缺actual PID/starttime與exact退出證明。Human全程觀察公開投影為zero／complete，但只綁machineSHA，無原協定publicreceipt。停點摘要見experiments/E016/evidence/first-stop-summary.json，不補造原receipt。

已確認path normalization策略bug，無當次runtime path因此不稱唯一根因。Implementer只回修E016共用Foundation雙側helper／hello path與Python samefile握手；純Foundation正反checks及20mock checks通過，待Tester/Reviewer。沒有build主App／sign／launch／DPK／新run，舊App與consumed markers不動；任何新準備／run須Human續行。

## 2026-11-16 path fix 最終離線審查

獨立Tester：20Pythonchecks、實際共用Foundationhelper alias/不同物件正反測試、format/lint/diffcheck通過，production零diff。Reviewer approved（bounded path fix／離線證據），required fix closed，無其他required fix。本次T09維持無法判定，first已耗用/fresh未執行，Human完整觀察zero，缺exact process exit/publicreceipt限制保留。不恢復額度、不自動重試；任何新準備與live序列須Human明確新額度。

## 現行結果與最終文件交接（2026-11-16）

Tester已完成[系統驗證紀錄](evidence/e016-live.md)與E016獨立success-summary projection；Reviewer獨立核原收據、attestations、frozen來源及兩exactprocess退出，最終approved本次有限實驗。T09實驗狀態成功／驗證任務完成；S06 Human最終review仍pending。

本次first/fresh皆使用固定bb6752aa483a68043174723a6b3ff2653abe79ce的同一signedbinary/profile/source；後續文件commit不是受測來源，不需要重跑歷史run追逐文件hash。適用當次同機／同GUI使用者／既有signer與有效profile／exactgroup／synthetic／uniquewriter；不外推真OAuth／UI／其他profile／crosswriter／durability。晚到refresh沿11/13受控tests，本次未做refresh/network。

ff672c7舊first無法判定與已耗額度保留；Human新增序列first/fresh也已使用完，不恢復或重試。configuration/sentinel未清理；原public Humanunknown/false由另立attestation補充且綁SHA，不覆寫machine/public/private。只允許最終文件一致性審查／既有Git交付與Humanreview，不再build/sign/launch/DPK。

## 最終文件交付審查

2026-11-16獨立Reviewer approved（最終文件／evidence一致性），無required fix。T09本次有限成功、來源bb6752a、八項receipt/hash綁定、歷史停點與適用限制已核對；S06 Human最終review仍pending。後續只提交文件／push／更新Draft PR，不merge或追加live操作。
