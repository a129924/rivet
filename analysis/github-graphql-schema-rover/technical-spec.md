# GitHub GraphQL Schema Rover — Technical Specification

## Locked Decisions

- Topic slug 固定為 `github-graphql-schema-rover`。
- 根目錄 `Brewfile` 使用 Homebrew Core formula `rover`；不引入其他工具版本管理器。
- `docs/toolchain.md` 是 Rover 的長期工具鏈說明位置。
- Rover 供開發者以自己的 GitHub token 對 `https://api.github.com/graphql` 做 schema introspection；token 不寫入 repository。
- 本 topic 不建立下載命令、腳本或 `Schema.graphqls` 快照。

## File Impact Contract

### Written

- `analysis/github-graphql-schema-rover/requirements.md`
- `analysis/github-graphql-schema-rover/technical-spec.md`
- `plan/github-graphql-schema-rover/github-graphql-schema-rover.plan.md`
- `plan/github-graphql-schema-rover/github-graphql-schema-rover.step.md`
- `Brewfile`

### Modify

- `docs/toolchain.md`

### Deleted

無。
