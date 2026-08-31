---
name: build-run-debug
description: Build, run, and debug macOS apps with shell-first Xcode and Swift workflows. Use when launching apps or diagnosing build, startup, or runtime failures.
---

# Build / Run / Debug

## Quick Start

Use this skill to discover the project shape, run the narrowest suitable build
or launch command, and diagnose build, startup, or runtime failures.

Prefer shell-first workflows:

- an existing project-local build or run entrypoint when one is already provided
- `xcodebuild` for Xcode workspaces or projects
- `swift build` plus raw executable launch for true SwiftPM command-line tools
- an existing `.app` bundle or the project's documented launch method for SwiftPM AppKit/SwiftUI GUI apps
- `lldb`, `log stream`, or process checks when they directly test the reported failure

Do not assume simulators, touch interaction, or mobile-specific tooling.

If an Xcode-aware MCP surface is already available and the user explicitly wants
it, use it only where it fits. Keep that usage narrow and honest: prefer it for
Xcode-oriented discovery, logging, or debugging support, and do not force
simulator-specific workflows onto pure macOS tasks.

## Workflow

1. Discover the project shape.
   - Look for `.xcworkspace`, `.xcodeproj`, and `Package.swift`.
   - If more than one candidate exists, explain the default choice and the ambiguity.

2. Resolve the runnable target and process name.
   - For Xcode, list schemes and prefer the app-producing scheme unless the user names another one.
   - For SwiftPM, identify executable products when possible.
   - Split SwiftPM launch handling by product type:
     - use raw executable launch only for true command-line tools,
     - use an existing `.app` bundle or request the documented launch method for AppKit/SwiftUI GUI apps.
   - Determine the app/process name to kill before relaunching.

3. Choose an existing build or launch entrypoint.
   - Prefer the project's documented command or a checked-in local script when it directly matches the task.
   - Otherwise use the narrowest direct `xcodebuild`, `swift build`, executable, bundle, debugger, or log command that tests the reported behavior.
   - Do not initialize a repository, create a run script, stage a new app bundle, or configure an environment action unless the caller explicitly requests that separate setup work.
   - Do not recommend direct SwiftPM executable launch for AppKit/SwiftUI GUI apps unless diagnosing that launch mode; use an available `.app` bundle or request a launch method.

4. Build and run with the selected entrypoint.
   - Add a debugger, log stream, or process check only when it provides evidence for the current question.

5. Summarize failures correctly.
   - Classify the blocker as compiler, linker, signing, build settings, missing SDK/toolchain, script bug, or runtime launch.
   - Quote the smallest useful error snippet and explain what it means.

6. Debug the right way.
   - Use available logs, Console, `log stream`, or captured process output for config, entitlement, sandbox, and action-event verification.
   - For SwiftPM GUI apps, if the app bundle launches but its window still does not come forward, check whether the entrypoint needs `NSApp.setActivationPolicy(.regular)` and `NSApp.activate(ignoringOtherApps: true)`.
   - Use direct `lldb` if symbolized crash debugging is needed.
   - If the user needs to instrument specific window, sidebar, menu, or menu bar actions, add the smallest suitable telemetry.
   - Keep evidence tight and user-facing.

7. Use Xcode-aware MCP tooling only when it helps.
   - If the user explicitly asks for XcodeBuildMCP and it is already available, prefer it over ad hoc setup.
   - Use the MCP for Xcode-aware discovery or debug/logging workflows when the available tool surface clearly matches the task.
   - Fall back to shell commands immediately when the MCP does not provide a clean macOS path.

## Preferred Commands

- Project discovery:
  - `find . -name '*.xcworkspace' -o -name '*.xcodeproj' -o -name 'Package.swift'`
- Scheme discovery:
  - `xcodebuild -list -workspace <workspace>`
  - `xcodebuild -list -project <project>`
- Build/run:
  - `xcodebuild build -workspace <workspace> -scheme <scheme>`
  - `xcodebuild build -project <project> -scheme <scheme>`
  - `swift build`
  - `/usr/bin/open -n <existing-app-bundle>`

## Guardrails

- Prefer the narrowest command that proves or disproves the current theory.
- Do not create or change repository, run-script, bundle-staging, or environment configuration as an incidental part of debugging.
- Do not launch a SwiftUI/AppKit SwiftPM GUI app as a raw executable unless the user explicitly wants to diagnose that failure mode: it can produce no Dock icon, no foreground activation, and missing bundle identifier warnings. Keep raw executable launch only for true command-line tools.
- Do not claim UI state you cannot inspect directly.
- Do not describe mobile or simulator workflows as if they apply to macOS.
- If build output is huge, summarize the first real blocker and point to follow-up commands.

## Output Expectations

Provide:
- the detected project type
- the command you ran
- whether build and launch succeeded
- the top blocker if they failed
- the smallest sensible next action
