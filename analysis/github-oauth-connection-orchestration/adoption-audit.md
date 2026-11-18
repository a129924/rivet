# OAuth 啟動／重連：有界採用盤點

## 查核範圍

觀察日期 2026-11-17；Rivet source revision `ab77391b73291deb1ce3d96cef72f981aeb3104a`。來源集合是 [source-audit](source-audit.md) 的 S01–S06、所列正式測試定義、E014 source／既有 live 紀錄、正式 signOut／login／scope 契約。本輪補建 A01–A06 識別，不回寫歷史；沒有把缺 tracker 當未採用依據。

正式查核範圍為 `Sources/BoundedContexts/GitHubIntegration/` 的 configuration／stores／OAuth factory／provider／composition／login，以及其相關 Tests；E014 僅作驗證工具對照。排除 PAT client 接入、UI 工作線、所有其他實驗／BC、即時遠端狀態及 live。原碼可讀，Swift tests 只讀未重跑；報告不涵蓋全專案採用狀態。

## 能力／決策明細

| ID | 能力／適用條件 | 採用程度 | 方式 | 正式實作／接入／行為證據與缺口 |
| --- | --- | --- | --- | --- |
| A01 | 冷啟動 configuration → provider → scope | 部分採用 | 既有等效 primitives，擬重用 | S01／S02／S04 正式機制與 scope 測試定義存在；上層正式 startup 接入缺少，不能把驗證 App 當產品。 |
| A02 | absence 與 restore／refresh／persist 分類 | 部分採用 | 重用既有 errors | S03／S04 已映射，lifecycleFailuresAreSanitized 定義可查；產品呈現與整條復原未接入。初次登入保存不細分是明確排除。 |
| A03 | 重新授權前退休並等 save／clear | 部分採用 | 重用正式 signOut，取代 E014 清 references 的做法 | S03 與兩 barrier 測試支持 primitive；S05 要求排除舊 writer。尚無串起 signOut→login→new scope 的正式 owner／行為證據。 |
| A04 | 正式上層串起成功登入→新 provider／scope | 未採用 | 擬新增受限組裝，不搬入 harness | S04／S05 沒有呼叫彼此；正式 Sources 的查核及 README 的產品接入 pending，與 E014 App-local coordinator 明確分離，是有界未落地依據。 |
| A05 | E014 工具直接作正式 orchestration／沿用其 adapter | 已排除 | 不採用 | Human 鎖定只交方案；S06 retire 僅 references，且同名 adapter 來源不同。UI、probe、受控時鐘、觀察收據沒有本輪正式用途。 |
| A06 | 既有正式 primitives 是否源自 E014 | 不確定 | 來源關係未知 | 能證明行為等效不代表來源採用。未進行全歷史 blame／作者採用紀錄對照，不宣稱由 E014 搬入；本輪方案不需要此來源主張。 |

此表的部分採用表示正式 primitives 已有、目標整合剩餘；沒有將來源關係不明偽裝成 E014 採用成功。沒有項目在本輪新增正式接入，因此無新增「已採用」判定。

## 未完成／排除與下一個證據

A01–A04 需要未來受限實作契約，指定唯一 owner、世代結果過濾、序列化、錯誤呈現，並測完整交接及取消。A06 若需要來源追溯，另查歷史 commits／既有採用紀錄；不以檔名相似判定。A05 與 PAT／產品 UI／初次登入 error 變更明確排除，避免重列待辦。

## 完成判斷

本輪報告 **COMPLETE**：分類均有有界證據或明確缺口；可包含 A06 不確定項，不代表正式 orchestration 已完成。驗證實驗未執行、文件驗證任務完成、採用程度與本報告完成各自獨立。未執行 Swift tests／live，不宣稱新 runtime 保證。
