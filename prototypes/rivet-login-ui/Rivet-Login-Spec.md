# Rivet · macOS Login UI Specification

**Version:** 1.0 · **Status:** UI design handoff · **Target:** macOS 13+ / SwiftUI · **Provider:** GitHub.com only · **Architecture:** Native client, no Rivet backend

> This specification defines an experience and visual contract. `RivetLoginView.swift` is a visual SwiftUI scaffold, **not** a working OAuth implementation. `Rivet-Login-Prototype.html` is an offline UI demo; it does not contact GitHub or store credentials.

## 1. Design intent and non-goals

- Use **Product Welcome / two-pane onboarding**, rather than a settings-style login form.
- Left 40% of the window communicates Rivet's value as a PR Diff Reader. Right 60% is the only interaction area.
- Main CTA: **Continue with GitHub**. Secondary text link: **Use a personal access token →**.
- Never ask a normal user for `Client ID` or `Client Secret`. Neither belongs in the login UI.
- No Rivet account creation, password collection, GitHub Enterprise selection, or provider selector in v1.
- Keep the brand panel stable while the right pane changes among login, browser wait, token, loading, and error states.

## 2. macOS window

| Property | Value |
|---|---|
| Nominal window | **780 × 500 pt** |
| Brand pane | **312 pt** (40%) |
| Auth pane | **468 pt** (60%) |
| App titlebar / traffic lights safe region | about **44 pt** at top; verify on supported macOS versions |
| Brand content insets | leading/trailing 30 pt; top 66 pt; bottom 32 pt |
| Auth content insets | leading/trailing 47 pt; top 58 pt; bottom 27 pt |
| Primary button | 42 pt tall, 10 pt corner radius |
| Token input | 40 pt tall, 9 pt corner radius |
| Border | 1 pt, low-contrast |
| Shadow | rely on native window shadow; diff preview can have subtle internal shadow |
| Window behavior | single-purpose login `Window`, centered initially; no full-screen button necessary; do not draw traffic lights manually |

**SwiftUI scene hookup (adapt to the existing `App`):**

```swift
Window("Welcome to Rivet", id: "rivet-login") {
    RivetLoginView(
        phase: $authenticationPhase,
        onGitHubSignIn: { authViewModel.beginGitHubLogin() },
        onCancelSignIn: { authViewModel.cancelLogin() },
        onTokenSignIn: { authViewModel.loginWithToken($0) },
        onRetry: { authViewModel.retryLogin() }
    )
}
.windowStyle(.hiddenTitleBar)
.defaultSize(width: 780, height: 500)
.windowResizability(.contentSize)
```

The snippet assumes `authenticationPhase` and `authViewModel` are supplied by the App owner. Mac window chrome stays system-owned. On newer macOS releases, verify titlebar inset and traffic light alignment rather than assuming a pixel-identical layout across OS versions. Under accessibility text enlargement, permit content/window growth instead of clipping a form.

## 3. Brand pane (312 pt)

Brand pane appears at all login states; it is **decorative, noninteractive** and does not display live PR data before authentication.

1. Top logo zone at x = 30 pt, y ≈ 66 pt. Rivet mark: 36 × 36 pt, radius 10. `RIVET` label: 13 pt semibold/heavy and letter spacing 1.3 pt.
2. Diff card starts approximately 150 pt from window top, 252 pt maximum content width. Card radius 12 pt, low-contrast border, dark monospaced preview.
3. Diff illustration can contain `ReviewDiff.swift`, `+2 −1`, a hunk marker, a red removal row, and two green addition rows. It is a **static illustration**, not GitHub data.
4. Bottom line: `Review the change.\nNot the noise.` in 23 pt bold. Supporting text: `A focused workspace for\npull request reviews.` in 12 pt.
5. Use subtle brand gradient or vignette, never a high-saturation illustration that competes with the CTA.

The brand pane is deliberately **dark in both appearance modes**, with a slightly deeper shade under Dark Mode. Decorative diff rows are excluded from the VoiceOver reading order or summarized as one noninteractive illustration.

## 4. Right auth pane (468 pt)

**Common structure:** eyebrow `GITHUB CONNECTION` aligned left near top; state-dependent content vertically centered; fixed footer separated by a hairline containing a lock icon and brief privacy text. Width after 47 pt horizontal inset: **374 pt**.

### Welcome (`.welcome`)

- Eyebrow: `WELCOME TO RIVET`, 10 pt bold, tracking 1.2.
- H1: `Review code,\nnot clutter.`, 26 pt bold, tracking approximately −0.65.
- Supporting text: `Connect your GitHub account to explore pull requests, read diffs, and stay focused on changes.`, 13 pt regular, ~1.5 line height.
- Main button: GitHub mark + `Continue with GitHub`, 374 × 42 pt; top gap around 30 pt.
- Secondary text button: `Use a personal access token →`, 12 pt underlined, centered, gap ~16 pt below main button.
- Footer: `Rivet never asks for your GitHub password` (applies to browser sign-in; token entry has separate footer).

**Interaction:** GitHub click calls the authentication service exactly once, disables repeat attempts and lets macOS display its standard browser authorization dialog. PAT link transitions within the right pane, without opening another Rivet window.

### PAT (`.tokenEntry`)

- Link above heading: `← Back to GitHub sign in`.
- Eyebrow: `ALTERNATIVE SIGN IN`.
- H1: `Connect with\nan access token.` (24 pt to keep the form inside the window).
- Description: `Use a fine-grained personal access token for GitHub.com.`
- Input label: `Personal access token`. Use `SecureField`; optional Show/Hide button, with visibility reset on exiting this state.
- Placeholder: `github_pat_…` is illustrative only. Do **not** validate solely by prefix; accepted token formats can change.
- Hint: `Recommended: grant only the repository access Rivet needs.`
- External link: `Create a fine-grained token ↗` → <https://github.com/settings/personal-access-tokens/new>.
- Primary: `Connect to GitHub`. Disabled only when the trimmed input is empty or while a request is underway.
- Footer: `Token stored in macOS Keychain` (only make this assertion after Keychain storage is implemented).

**PAT behavior:** trim exterior whitespace, validate against GitHub (`GET /user` or GraphQL `viewer`), store in Keychain on success, and check PR access separately. Do not print the token, retain it in logs, put it in `UserDefaults`, or pass it into telemetry. Clear visible input after successful storage or abandonment. No token is needed in the mock HTML.

### OAuth in progress (`.waitingForBrowser`)

- Small system spinner, then `Finish signing in\non GitHub`.
- Description: `Your browser is handling authorization. Rivet will continue automatically when you return.`
- Quiet status strip: `Waiting for GitHub authorization…`.
- Secondary operation: `Cancel sign in` → stop the authentication session and return to `.welcome` without an error banner.
- No additional user verification code for the planned browser OAuth flow. Do not put a fake `Open GitHub` deep-link into the native App's waiting UI; `ASWebAuthenticationSession` owns the browser session.

### Validation (`.verifyingAccount` / `.verifyingToken`)

- System `ProgressView`; no re-clickable primary action.
- OAuth: `Connecting your GitHub account…`; Token: `Checking your token…`.
- Do not show a success toast before the API user identity and required local Keychain write complete.

### Success (`.connected`)

- Brief checkmark state: `You're connected.` / `Your GitHub account is ready. Rivet will now open your pull requests.`
- Automatically transition to Rivet's main PR reader rather than asking for another confirmation click. The main view should handle any repository-level permission or empty-state message.

### Errors (`.failure`)

| Case | In-product copy | Behavior |
|---|---|---|
| Browser authorization cancelled | No visible error | Return to welcome |
| Browser/transport error | `Couldn't connect to GitHub. Check your connection and try again.` | Retry + optional PAT link |
| OAuth `state` mismatch, expired code, callback mismatch | `The sign-in session expired. Please try again.` | Clear pending session; start a fresh PKCE flow |
| Token rejected / revoked (`401`) | `This access token isn't valid anymore.` | Keep PAT form available, avoid displaying full token |
| Repository access missing (`403`/organization approval) | `You're connected, but Rivet can't access this repository.` | Show repo permission recovery in main workspace, not a global login failure |
| Rate limit | `GitHub requests are temporarily limited. Please try again shortly.` | Respect rate-limit response headers/backoff |

Never treat every `403` as an invalid token; GitHub can deny repository operations or impose rate limits after a valid login.

## 5. Light and Dark design tokens

| Semantic token | Light | Dark |
|---|---|---|
| Auth background | `#FCFDFF` | `#161C26` |
| Primary text | `#192533` | `#F4F6FA` |
| Secondary text | `#647386` | `#9AA9B9` |
| Hairline/border | `#E1E7EE` | `#323C49` |
| Subtle surface | `#F1F4F8` | `#222C39` |
| Text-field background | `#FFFFFF` | `#19232E` |
| GitHub CTA background | `#252B33` | `#F3F6FA` |
| GitHub CTA label | `#FFFFFF` | `#19212C` |
| Brand gradient top | `#223A54` | `#19293C` |
| Brand gradient bottom | `#0F1C2F` | `#0E1725` |
| Diff card bg (both) | `#0C1828` | `#0C1828` |
| Diff addition bg | `#1D4D3D` | `#1D4D3D` |
| Diff removal bg | `#512E36` | `#512E36` |

Keep brand colors deliberate but use semantic SwiftUI/AppKit colors for dynamic native controls when possible. **Default to following macOS `colorScheme`**; avoid putting a theme switcher in the actual login UI. The Light/Dark switch is only for the HTML design preview. Test with increased contrast, graphite accent, reduced transparency, and VoiceOver.

## 6. Typography and spacing

- Font family: `system` / SF Pro; diff code: `monospaced` / SF Mono fallback. **Never ship Apple system font files.**
- H1: 26 pt, bold (PAT H1 24 pt).
- Brand tagline: 23 pt, bold.
- Description: 13 pt regular, line spacing 3 pt.
- Eyebrow: 10 pt bold, tracking 1.2 pt.
- Links / inline actions: 12 pt; small helper: 11 pt.
- Reusable vertical spacing tokens: 4 / 8 / 12 / 16 / 24 / 30 pt.
- Minimum keyboard focus: always preserve a visible focus ring; do not replace native accessibility focus with color alone.

## 7. Authentication architecture and security (separate from View)

Suggested ownership:

```
RivetApp / WindowCoordinator
  └─ AuthenticationViewModel (@MainActor)
       ├─ AuthenticationService (OAuth / PAT)
       │    ├─ ASWebAuthenticationSession
       │    ├─ URLSession (GitHub REST / GraphQL)
       │    └─ TokenStore (Keychain)
       └─ RivetLoginView (state + callbacks, no networking)
```

**Native browser flow:** user clicks → OS authorization sheet/browser → GitHub callback to registered scheme/HTTPS callback → compare `state` → exchange code with PKCE verifier → validate `GET /user` → save token to Keychain → open main window. Use a retained authentication session, protect against duplicate starts, avoid printing auth codes/tokens, and handle window closure or cancellation cleanly.

**Important constraint:** GitHub's documented standard OAuth web flow currently requires a `client_secret` to exchange the code even when PKCE is used. A standalone public macOS binary **cannot keep an embedded secret confidential**. PKCE mitigates authorization-code interception but does not turn that client secret into a safe secret. The UI must remain independent of the final mechanism. If that tradeoff is unacceptable, select the supported alternative (for example Device Flow with extra user-code interaction, or user-provided PAT), then revise only the status copy and entry flow. Do not represent PKCE alone as a way to eliminate GitHub's token-exchange secret requirement.

**Recommended API test:** after authentication, call `GET https://api.github.com/user`, then make a small read-only PR GraphQL query and a private-repository PR read to separately verify actual repository access. GitHub App installation/approval and PAT grants are different from account identity.

## 8. SwiftUI handoff and QA checklist

- [ ] Build a real macOS `Window` (not a custom webpage) and keep native traffic lights unobstructed.
- [ ] Honor system Light/Dark Mode automatically; no theme control in shipped login.
- [ ] GitHub button is primary, PAT is text link. No Client ID / Secret fields in user-facing UI.
- [ ] PAT uses `SecureField`, allows Show/Hide, avoids prefix-only validation, and never logs a token.
- [ ] OAuth waiting / checking / failed / cancelled states render without layout shift or second Rivet window.
- [ ] Network or OAuth failure is recoverable; cancellation isn't shown as an error.
- [ ] Verified identity token is stored in Keychain; relaunch restores session and skips login when valid.
- [ ] Org/repo access failures are displayed separately from login failures.
- [ ] VoiceOver reads the right-hand interactive content before decoration; logical keyboard tab order; visible focus.
- [ ] Snapshot-test welcome, PAT, waiting, and error in Light/Dark, including higher text contrast.
- [ ] For large accessibility text sizes, avoid clipped content by allowing the window/layout to grow or scroll.

## 9. Authoritative implementation references

- Apple · ASWebAuthenticationSession: <https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/>
- Apple · SwiftUI windows: <https://developer.apple.com/documentation/swiftui/windows>
- Apple · Dark Mode HIG: <https://developer.apple.com/design/human-interface-guidelines/dark-mode>
- GitHub · OAuth App best practices: <https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app>
- GitHub · Authorizing OAuth Apps: <https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps>
- GitHub · Fine-grained PAT management: <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens>
