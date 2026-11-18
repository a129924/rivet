# E016：正式本地登出與 fresh-process 驗證

## 結果與適用範圍

2026-11-16，Tester在Human明確授權的修正版新額度下，於同機、同GUI使用者、同一有效既有簽章/profile、同一隔離namespace且唯一writer的前提，執行first一次與fresh一次。兩段machine皆passed，actual exact processes分別歸屬及退出有私有PID/starttime/path/hash證據；fresh與first為不同exact process。兩段Human皆確認全程觀察、prompt class為zero，attestation各綁其原public receipt SHA。

**T09本次有限實驗成功，驗證任務完成。** 主session於2026-11-16轉交獨立Reviewer最終明示approved，範圍僅本次E016結果與限制；不是Human最終topic接受，也不回寫舊停點為成功。

## 凍結來源與環境

- 歷史受測commit：`bb6752aa483a68043174723a6b3ff2653abe79ce`；本文件之後的文件commit不是受測版本。
- Xcode26.6／17F113、Apple Swift6.3.3、Python3.14.0。有效profile每段啟動前均重驗；expiry前提只支持當次執行。
- source manifest SHA-256：`1404bf775c97e80166665bc11f73043f662edf2b96c2ab15cedf8f8906b527f0`。
- signed binary SHA-256：`9ff2bc8ebf069ae2ae8c7c2d3a068db83cd653c69bd6b80bc12cdacf8850e336`。
- embedded profile SHA-256：`8b7cabcd79f3732a48c964eea5ee85576b8416b33b87d8144affcc0964dd3bd9`。
- signing transition SHA-256：`bfe1ff4852a18d31c15f07f2122da3de4b61a652f6083f465680e04feed4623e`。
- frozen provenance SHA-256：`1778db8b577e6c0619b32a9c5edc208bb20fc2270ec7692b2cd208f428dbdabc`。
- preflight public SHA-256：`61413f59f0ad2eb16bc396ba320630bb20d98cdc9429f7f3fa4fdd547e17e5b4`。
- 原始App/runroot、PID/starttime/path、身份與原始attestation保留私有，不輸出fixture payload或提示原文。

## 實際操作與觀察

實際命令從feature worktree執行；以下變數分別指向既定且受審的同一signed App與owner-only runroot，並非授權重跑入口：

```sh
python3 -B experiments/E016/scripts/e016_live.py first --app "$E016_APP" --run-root "$E016_RUN_ROOT"
# 核first machine passed、exact process已退出及Human完整觀察attestation後
python3 -B experiments/E016/scripts/e016_live.py fresh --app "$E016_APP" --run-root "$E016_RUN_ROOT"
```

每段前Tester只讀重核clean bb6752a來源、source manifest、binary/profile、簽章與transition、profile有效性、related-process absence及該段未消耗。fresh前另核first passed／frozen binding／exact process stopped／Human attestation綁定。中間沒有rebuild、re-sign、換App、換runroot或source改動。

| 段落 | 實際觀察 |
| --- | --- |
| first | 三項初始absence；保存完整synthetic credential、configuration及sentinel；逐欄readback相符；正式public OAuthTokenProvider.signOut返回；同程序主credential absent，configuration／sentinel完整保持。 |
| fresh | 新exact process只讀；credential absent、configuration／sentinel完整保持，write_attempted=false；first與fresh均已退出。 |

兩個CLI皆exit0。所有machine/frozen/private hash綁定核對相符。fresh的previous_process_terminated=true，私有receipt與即時stopped(pid,start)重新檢查支持兩段exact process均已退出；不以同名pgrep取代本次證據。

## 收據與後補Human觀察

下列原machine/public/private receipts保持原bytes。原public由runner寫入Human observation unknown／false，之後沒有覆寫；Human已確認的全程觀察與zero class由另外attestation補充並綁原public SHA。Tester只核綁定，不冒充自己看見全部提示。

| 收據 | first SHA-256 | fresh SHA-256 |
| --- | --- | --- |
| machine | `3020c4a540cce5614cb408cba936797c02417b93c255fbcacde5510fe4d20af9` | `dcf802454c82a6b73f209348fbf7de26019e9cc98a81700e935002a07072d2f0` |
| original public | `cf1d164fc980ec561c2a963482b78ea0e800a0b96cdf2dfe921c0953ead06ac6` | `7cd0bffe8f7e61a847cb366e13959da442736c918108d920203a0ac582814307` |
| private provenance | `960578ff9eaaf9e72486c828346c6e3de5dd93f17b08b9ad97971ee6b1c43260` | `428df714ec10002407993a916427be9c794feb221d1ed8fbf00c5f1bcff23e68` |
| Human attestation | `e9944a00e07a9d53ca3cf77679cf819a391b51d39bacb87ad64f62d8ea919889` | `de07376799ea85184237348ffe388bb889038f1a0af7bdc7501b1864e90e1785` |

公開彙整位於[success-summary.json](../../../experiments/E016/evidence/success-summary.json)，使用獨立`e016.success-summary.v1` schema；它是結果projection，不能當成原協定machine/public receipt。

## 歷史、額度與限制

- ff672c7的first在hello前停止、budget已消耗、outcome indeterminate；缺exact-process/public/fresh證據保持原樣。path policy bug已確認，但當次唯一runtime根因未證明。舊App／marker／receipts未修改。
- 修正版bb6752a新準備與新增一次first/fresh額度由Human另行明確授權；本次first與fresh兩段均已使用完，沒有自動重試或恢復舊額度。
- 本次保留隔離configuration及sentinel，無cleanup／追加Keychain讀寫；不得將殘留當成已刪除。
- 正式DPK與signed host為真依賴，credential/configuration/sentinel為synthetic；沒有真OAuth授權、refresh/network或產品UI驗收。晚到refresh競態沿11/13正式受控tests，並非本次live重驗。
- 只支持當次同機／GUI使用者／signer／profile與唯一writer；不外推其他signer、profile更新、跨程序writer、自然到期refresh、斷電durability或所有環境。
- 不再執行任何App、build、sign、preflight、seed、delete或fresh；Human最終topic review仍pending。
