# TE01 獨立驗證

日期：2026-11-17。Tester 獨立於 IM01 Implementer；source revision `ab77391b73291deb1ce3d96cef72f981aeb3104a`。範圍：本 topic 文件／圖面／本機 Floorplan，不執行 Swift runtime、live OAuth 或 DPK。

## 結果與修正歷史

**TE01：COMPLETE，可交獨立 Reviewer。** 首輪 NEEDS_REWORK 僅因 `source-audit.md` 的 signOut 長期契約連結指向不存在檔案。Implementer 改為 `docs/architecture/github-oauth-dual-client.md#本地登出` 後，Tester 重驗路徑及章標題；原失敗保留於 [verification.json](verification.json) 的 history，未將它覆寫成首輪通過。

## 親跑檢查

| 檢查 | 實際結果 |
| --- | --- |
| Python 來源 manifest SHA-256 比對 | 20/20 相符，與指定 source revision 的本輪受查檔案一致。 |
| Python 本題 Markdown 相對 links／source line 範圍 | 首輪 34 links 中 1 broken；修正與驗證證據保存後所有 37 相對 links 存在，修正章標題存在。 |
| `git diff --name-only HEAD -- Sources Tests Package.swift Package.resolved AGENTS.md .gitignore` | exit 0，空清單；production／tests／package／共同設定 tracked diff 為零。 |
| `git ls-files --others --exclude-standard` | exit 0，首輪 35 個未追蹤成果全部在本 topic allowlist；Floorplan ignored。驗證自身新增 evidence 亦限本 topic。 |
| `git diff --check` 與新文件 trailing-whitespace 檢查 | exit 0；24 份 Markdown／JSON 無尾端空白。 |
| Archify `validate sequence …cold-start.sequence.v2.json --quality showcase --json` | exit 0，9/9 checks，composition errors=0、warnings=0。 |
| Archify `validate lifecycle …reauthorization.lifecycle.v2.json --quality showcase --json` | exit 0，9/9 checks，composition errors=0、warnings=0。 |
| deliver／visual 收據與實際 bytes | 兩份 v2 spec、HTML SHA-256 相符；四 viewport containment／readability pass，兩圖共 8 張明暗截圖存在。首版 v1 與 visual-history 保留，不將 v1 當 final input。 |
| Floorplan graph／provenance／描述與 refs | 20 files／2602 LOC，20/20 描述、7/7 module summary、0 unassigned；50 links 均有端點，10 條 explicit call 關係逐一對原碼；無 scope mismatch。graph／index SHA 與 provenance 相符。 |
| Floorplan 使用者內容與工具限制 | 本工作樹原 status none；目前無原始 notes／custom-flows 可遭覆寫，architecture annotations 保留，recent tasks=[]。只讀核對，不重建圖或啟 server／Ask。 |

命令中的省略路徑皆為 `analysis/github-oauth-connection-orchestration/diagrams/`；Archify 執行使用 skill 指定的本機 CLI。機器摘要、雜湊及首輪失敗詳見 verification.json。

## TC01–TC10 對照

- **TC01–TC02：原碼／文件一致。** 正式 store 將 nil 與 error 分開；scope 分類 missingCredential／authenticationRequired／restore／refresh／persist，Bearer 與取消檢查在 clients／scope 交付前。local ready 不代表遠端通過。這是來源查核，不是本輪 runtime pass。
- **TC03–TC05：候選方案及證據界線一致。** provider 退休後阻止晚到 refresh save；已開始 write settle 後 clear；登入 worker 等完整收尾，save 後取消可能留下新 credential。既有 signOut 測試含兩 barrier 定義；PAT during-save 不冒稱 OAuth barrier。上層重連／世代 owner 未實作，完整串接未驗證。另已核對現有登入 public initializer 要求 PAT store，而其 constructor 不操作 Security，OAuth 分支不呼 savePAT；僅記既有依賴，不擴 PAT 連線。
- **TC06：盤點／採用語義一致。** A01–A03 部分採用、A04 未採用、A05 明確排除、A06 來源關係不確定；未將等效能力推論為源自 E014，未新增已採用或修改歷史結果。
- **TC07–TC08：現況 map 與歸屬一致。** 正式 12／E014 5／tests 3 共 20 檔；相對 paths／描述均有對應。E014 同名 App-local stores 與正式 stores 分開，沒有虛構正式 login→scope 或 orchestration 節點。Swift 靜態 mentions 不視為 async／actor／動態綁定完整證據。
- **TC09：工具驗證及收據一致。** 最終 v2 spec 兩次獨立 validator 通過；既有四尺寸及 screenshot 收據與 HTML hash 一致。沒有再次執行 deliver／visual-check，Agent 作者的視覺檢查與 Human pending 分開。
- **TC10：範圍、links、版本可追溯。** 只本 topic 與獨立採用紀錄；沒有新 live／實驗／正式程式變更。PR Lens 留到 DL01 actual diff，不在 TE01 宣稱完成。

## 限制與未執行項目

未執行 Swift build／tests、新 fake 實驗、完整 runtime 或 live；原碼閱讀不代替上述結果。Floorplan routes 0/0 不適用，Health high/medium/low=0 不能當安全審查：endpoint check 未執行，工具有指向範圍外 E013 server 的 loud 提醒，已記於 map provenance。

本輪選擇不重建 Floorplan，以保留其 original graph／index hashes；故只獨立核對當前模型／描述／50 links／SHA 及先前 build 收據，不宣稱 Tester 親跑 Floorplan build。沒有製圖前 Git config snapshot，不將目前 zero diff 當作歷史位元比對；本次驗證操作前後之保護檔雜湊另行相等檢查。

Archify 圖帶可選 Google Fonts links，Floorplan 無外部 script／style URL；沒有啟動網路服務、Ask、model 或發布。Graphify 沒有既有 graph 故原碼 fallback，沒有新建 graph。Human 最終 review 與圖面接受仍 pending。
