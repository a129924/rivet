# GitHub PR GraphQL 寫入

套件內的 **RivetPRWriteGitHub** 提供 GitHub PR 寫入入口、GraphQL operations 與操作結果。呼叫端注入已就緒的 `GitHubGraphQLServing`。共用 client 負責 Bearer 與明確 HTTP `401` 後最多一次的認證復原。PR Reader 繼續供應讀取資料。 [PR Reader](bounded-contexts/pr-reader.md) · [API Catalog](../github-api/graphql-write-actions.md)

## 單檔標記與取消已讀

`PRFileViewedWriter.setViewed(_:)` 接受呼叫端已核對的 PR node ID、原始路徑和 `mark` 或 `unmark`。入口保留路徑的 UTF-8 原始字面。若呼叫端已知檔案清單換版，應先重新核對。GitHub 的 viewed mutations 以 PR ID 與路徑定位目標，呼叫端核對到 GitHub 執行寫入之間仍可能發生版本變更。 [GitHub markFileAsViewed](https://docs.github.com/en/graphql/reference/pulls#markfileasviewed) · [GitHub unmarkFileAsViewed](https://docs.github.com/en/graphql/reference/pulls#unmarkfileasviewed)

| 結果 | 證據 |
| --- | --- |
| 已接受 | 伺服器回傳同一 PR 的 ID，必要收據欄位未受 GraphQL errors 影響。 |
| 未送出 | 呼叫端輸入無效，或 adapter 在進入 `perform` 前觀察到取消。 |
| 明確拒絕 | 明確認證拒絕，或者 mutation payload 缺席且根欄位的結構化錯誤一致指向拒絕。 |
| 待核對 | 空 payload、PR 不符、必要收據欄位有不確定性，或提交後只取得取消、斷線等不足以確認的證據。 |

Adapter 對單次動作最多呼叫一次 `perform`。要確認當下逐檔三態，呼叫端或後續工作流可另行使用 [Files Viewed 讀取](bounded-contexts/pr-reader.md#github-graphql-files-viewed-讀取)。

## 離線再生成

使用 Apollo iOS 2.1.2 checkout 內的 CLI 與 Reader 固定的 `Schema.graphqls`。下列命令從 repository 根目錄執行，將輸出與已提交的 Swift 比對。若使用獨立 SwiftPM scratch path，將 `rivetswiftpm` 設成該路徑。Reader schema SHA-256 為 `a70103efc655a6b81afa69cdbce8b27d90d8202270b19ea54130e95c650047b7`。

~~~bash
set -e
read_input=Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls
write_graphql=Sources/RivetPRWriteGitHub/GraphQL
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/Codegen"
tar -xzf "${rivetswiftpm:-.build}/checkouts/apollo-ios/CLI/apollo-ios-cli.tar.gz" -C "$work"
cp "$write_graphql"/Codegen/* "$work/Codegen/"
cp "$read_input" "$work/Codegen/"
(cd "$work/Codegen" && ../apollo-ios-cli generate --path apollo-codegen-config.json)
python3 - "$work/Generated" <<'PY'
from pathlib import Path
import sys

header = (
    b"// swift-format-ignore-file\n"
    b"// swiftlint:disable:next blanket_disable_command\n"
    b"// swiftlint:disable all\n"
)
for path in Path(sys.argv[1]).rglob("*.swift"):
    path.write_bytes(header + path.read_bytes().rstrip(b"\n") + b"\n")
PY
diff -ru "$write_graphql/Generated" "$work/Generated"
~~~
