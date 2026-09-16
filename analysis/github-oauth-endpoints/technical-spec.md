# GitHub OAuth Endpoints：Technical Spec

## Boundary

`GitHubOAuthEndpoints` 是 `GitHubIntegration` 的 internal-only URL descriptor。它只描述 GitHub.com OAuth App 的兩個固定 endpoint；不建立或宣稱 request、network execution、payload、token exchange、refresh 或 credential lifecycle。實作完成後，這個狹義 descriptor ownership 結論回寫至 `docs/architecture/README.md`，不擴張既定 shared integration boundary。

## Interface

```swift
enum GitHubOAuthEndpoints {
  static let authorizationURL: URL
  static let tokenURL: URL
}
```

此 type 與 members 不宣告為 `public` 或 `package`。它不接受 host、path、environment 或 query configuration，也不 import HTTP、Security、Keychain、Apollo、`RivetHTTPClient` 或 Domain BC。

## Verification

- 使用 `@testable import GitHubIntegration` 的 focused tests 驗證 exact URL strings 與 URL components。
- static isolation 的 source-file exact set 納入 `OAuth/GitHubOAuthEndpoints.swift`，並維持 integration target 無 dependencies 與 forbidden-import assertions。
- 檢查 `docs/architecture/README.md` 的唯一架構回寫只陳述 internal fixed GitHub.com authorization／token URL descriptor 的 ownership，且未加入 request、payload、exchange、refresh 或 credential lifecycle 宣稱。
- 執行 root `swift test` 與 `git diff --check`。
