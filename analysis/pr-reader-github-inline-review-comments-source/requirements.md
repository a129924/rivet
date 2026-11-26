# 單一 PR 的 REST 行內審閱留言需求

套件內的 PR Reader 呼叫端提供已認證的 REST client 與 `ReaderPullRequestID`，一次取得指定 GitHub.com PR 的完整、有序行內留言。空清單是成功。無法確認分頁完整性或保留必要資料時，整次讀取回單一 Reader failure。完整性以當次 GitHub 提供的分頁序列為準，各頁可反映不同時間點。

1. 保留跨頁及頁內原序、來源頁次、精確 ID、node ID、原始正文、路徑、來源定位與回覆資料。
2. 合法缺少行號、範圍端點或回覆 ID 時保留留言與缺值。完整空清單回成功。
3. 拒絕錯誤目的地、其他 PR 或 repo、跳頁、循環及矛盾續頁。數字 repo ID 可核對其歸屬。
4. 無效 PR 識別或留言存取拒絕為 `.notReadable`。限流、傳輸、取消及分頁完整性失敗為 `.unavailable`。必要資料無法保真表達為 `.contentNotRepresentable`。失敗時無部分結果。

排除一般討論留言及審閱紀錄的行為變更、GraphQL `reviewThreads`、來源切換、thread 分組、快照與 UI 接線、GitHub 寫入及本機持久化。 [PR #99](https://github.com/a129924/rivet/pull/99) · [技術規格](technical-spec.md)
