# GitHub OAuth Dual Client Architecture：技術規格

## Goal

以文件鎖定既有、可 refresh 的 GitHub OAuth credential bundle 的雙 Client token lifecycle ownership，讓未來 REST 與 Apollo GraphQL infrastructure 可共享一份 token state，而不把 GitHub OAuth policy 放進 generic HTTP foundation。

## Non-Goal

本規格不定義或建立 Swift runtime API、OAuth authorization code flow、PKCE、callback、initial sign-in、logout、多帳號、client implementation、Apollo interceptor、package、module、test、Port 或 failure type。

## Locked Architecture Contract

```text
Facade（layer 外 application composition root）
  ├─ bare RivetHTTPClient / URLSessionTransport
  ├─ KeychainTokenStore
  ├─ OAuthTokenFetcher(bare HTTP)
  ├─ OAuthTokenProvider(TokenStore, TokenFetcher)
  ├─ GitHub REST client(TokenProvider, bare HTTP sender/request executor)
  └─ GitHub GraphQL client(TokenProvider, Apollo)
```

- `GithubIntegration` 是 BC 外、GitHub-specific 的 future shared integration module；它不成為 Bounded Context、不依賴 BC，亦不擁有 Domain Port、DTO translation、BC failure mapping 或 business meaning。
- `RivetHTTPClient`／`URLSessionTransport` 保持 bare、generic、raw 與 GitHub／OAuth-unaware。它不認識 OAuth、Bearer lifecycle、TokenProvider、401 recovery 或 retry。
- `RivetHTTPClient` 的 internal `AuthRequester` 以 injected `Requester` 與 caller-provided `Auth` 建立並驅動 generic `send → execute → receive` flow；Auth decision 由 flow 擁有。此 topic 不修改該 runtime，且此 generic flow 不承擔 GitHub OAuth lifecycle。
- 此 Facade 是 layer 外的 application composition root：建立單一共享 `OAuthTokenProvider` instance，並注入兩個 client；它不預先替每一個工作驗證 token，亦不改變各 BC 的 `Facade → UseCase → Port` 層級方向。
- 本 lifecycle 的 credential precondition 僅是已存在、可 refresh 的 OAuth credential bundle；本 topic 不選擇 OAuth App 或 GitHub App。

## Responsibility Contract

| Component | Responsibility | Prohibited responsibility |
| --- | --- | --- |
| TokenStore | 讀寫完整 OAuth credential bundle | request／operation、refresh policy、client retry |
| OAuthTokenFetcher | 只用 bare HTTP 呼叫 GitHub token endpoint，回傳完整 rotated bundle | Keychain state、REST／GraphQL request ownership |
| OAuthTokenProvider | memory snapshot、restore、expiry、refresh、rotation、version、single-flight | 持有、接收或重送 HTTPRequest／Apollo operation |
| TokenSnapshot | access token 與 version 的 immutable client input | 暴露 refresh token 或完整 credential bundle |
| GitHub REST client | 依賴 bare HTTP sender／request executor 與 TokenProvider；取得 snapshot、加入 Bearer、送出與重送自己的 HTTPRequest 一次 | OAuth／Keychain／refresh-token knowledge |
| GitHub GraphQL client | 取得 snapshot、加入 Bearer、以 Apollo retry 自己的 operation 一次 | 呼叫 REST client 或 token endpoint |

本規格不推導具體 Swift type、method signature、actor isolation annotations、storage schema、endpoint payload schema 或 error enum。

## Lifecycle Contract

1. REST 或 GraphQL client 取得目前有效的 `TokenSnapshot`。
2. client 在自己的 request／operation 加入 `Authorization: Bearer`，並走自己的 transport route。
3. 非 401 回應由 client 依自身 adapter boundary 處理；403、repository permission 與 resource visibility 不觸發 refresh。
4. 收到 401 時，client 將**本次實際使用的 snapshot**回報 Provider。
5. 若 Provider 已有更高 version，直接回傳目前 snapshot；若仍是相同 stale version，最多 single-flight 執行一次 refresh。
6. Fetcher 成功後，Provider 接受遠端 rotated bundle、保存完整 bundle、更新 memory snapshot/version，再讓等待者取得新版 snapshot。若 technical failure 發生在接受遠端 rotation 前，既有 credential 保留；若接受遠端 rotation 後發生本地 persistence failure，不宣稱舊 bundle 仍可用，credential reconciliation 留待後續獨立 topic。
7. 原 REST request 或原 Apollo operation 由原 client 以新版 snapshot 重送一次。每個原工作最多一次 recovery retry。
8. 無 credential、permanent refresh failure 或 retry 後第二次 401，產生 authentication-required／重新登入 outcome；尚未接受遠端 rotation 的 transient refresh／Keychain／network failure 不清除 credential，回 technical failure。

Provider 不接收 request／operation，也不擁有重送責任。REST 與 GraphQL 只共享 Provider instance，不共享彼此的 transport route 或工作物件。

## Scope Control

### In-Scope

本文件定義 architecture responsibilities、lifecycle semantics、failure 分類、Phase 1 planning artifacts 與 Phase 2 documentation delivery gate。

### Out-Of-Scope

初次 sign-in／PKCE／callback、logout／revoke、多帳號、PAT、GitHub Enterprise、rate-limit／pagination、Domain endpoint／DTO／failure mapping，以及一切 runtime implementation。

### ReadOnly

Phase 1 時，除四份 planning artifacts 外，runtime、package、tests、BC contracts、歷史 topics、long-lived docs 與 diagrams 全部 ReadOnly。

Phase 2 時，除下列 allowlist 外一律 ReadOnly：

- `docs/architecture/github-oauth-dual-client.md`
- `docs/architecture/README.md`
- `docs/architecture/diagrams/github-oauth-dual-client-architecture/`

### Written

Phase 1 只寫入四份 planning artifacts。Phase 2 僅在 independent Plan Review `approved` 後，才可寫入上述 allowlist。

### Modify

Phase 1 無修改。Phase 2 只可修改 allowlist 中既存的 `docs/architecture/README.md`；其他 long-lived file 僅能新增。

### Deleted

無刪除授權。

## Documentation Delivery Contract

independent Plan Review 是 long-lived docs 與圖表交付的前置條件。通過後才可：

- 以 `architecture-canvas` 製作繁體中文責任／依賴 canvas；它不表達 runtime sequence。
- 以 `archify` 製作繁體中文 token lifecycle，表達 snapshot → Bearer → 401 → provider recovery → one retry／terminal outcome。
- 對兩種圖表執行各自 skill validation；不得發布到 artifact.cafe。

delivery 必須保留 v1／v2 lifecycle artifacts 作 immutable rejected evidence，並在 diagrams allowlist 新增 canonical manifest，將已驗證交付的 v3 lifecycle 指為 canonical artifact。v3 lifecycle 必須表達 transient technical-failure terminal outcome，且區分 pre-rotation credential retention 與 post-rotation persistence failure 的 deferred reconciliation。責任／依賴 canvas 僅作 colour fix；不得改變責任、依賴或不表達 runtime sequence 的既定語意。

`github-integration-auth-boundary` 僅作 supersession traceability，不是本 topic 的可修改輸出。

## TestCase

- **TC-01**：責任圖不將 `GithubIntegration` 表示成 BC、Domain adapter 或 Domain Port owner。
- **TC-02**：責任圖不使 raw `RivetHTTPClient` 依賴 OAuth／TokenProvider；若提及 generic Auth flow，必須正確表達 internal `AuthRequester` 由 injected `Requester` 與 caller `Auth` 驅動 `send → execute → receive`，且不將其誤作 GitHub OAuth lifecycle。
- **TC-03**：lifecycle 圖呈現 stale version fast-path、same-version single-flight、rotation 後新版 snapshot 與原工作 one retry。
- **TC-04**：lifecycle 圖呈現 permanent authentication-required、transient technical failure（pre-rotation 保留 credential）、post-rotation persistence failure deferred reconciliation，及 403 no-refresh boundary。
- **TC-05**：v1／v2 lifecycle artifacts 保留為 immutable rejected evidence，canonical manifest 將已驗證交付的 v3 指為 canonical lifecycle；canvas colour fix 不改變既定 diagram semantics。
- **TC-06**：Phase 2 artifacts 只在 Plan Review approved 後產生，並通過對應 diagram validation。
