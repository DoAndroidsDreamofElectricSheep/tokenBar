# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TokenBar is a macOS menu bar app (macOS 14+) that monitors usage limits and quotas for 25+ AI coding platforms (Claude, Codex, Cursor, Gemini, Copilot, Augment, etc.). Built in Swift 6 with strict concurrency. Uses SwiftPM as build system.

This is a fork of [steipete/TokenBar](https://github.com/steipete/TokenBar).

## Build, Test, Run

```bash
swift build                        # Debug build
swift build -c release             # Release build
swift test                         # Full XCTest suite
swift test --filter TestClassName  # Single test class
./Scripts/compile_and_run.sh       # Full dev loop: kill, build, test, package, relaunch
./Scripts/package_app.sh           # Build TokenBar.app bundle
./Scripts/lint.sh lint             # Check linting
./Scripts/lint.sh format           # Auto-format
pnpm check                        # Lint + format check (run before handoff)
```

After any code change, run `./Scripts/compile_and_run.sh` to rebuild and restart the app.

## Linting & Formatting

SwiftFormat + SwiftLint enforced. Key rules:
- 4-space indent, 120-char lines
- Explicit `self` required (Swift 6 concurrency) -- do not remove
- Run `swiftformat Sources Tests` and `swiftlint --strict`
- Run `pnpm check` before handoff to catch all issues

## Architecture

### Module Layout

| Module | Purpose |
|--------|---------|
| `TokenBar` | macOS app: AppKit/SwiftUI hybrid, menu bar UI, settings, icon renderer |
| `TokenBarCore` | Shared logic: providers, usage fetching, config, logging, cookie/keychain handling |
| `TokenBarCLI` | CLI executable (`tokenbar` command) |
| `TokenBarWidget` | WidgetKit extension |
| `TokenBarMacros` / `TokenBarMacroSupport` | Swift Syntax macros for provider registration |
| `TokenBarClaudeWatchdog` | Helper: manages stable Claude CLI PTY sessions |
| `TokenBarClaudeWebProbe` | Helper: diagnostics for Claude web fetches |

### Provider Architecture (the core pattern)

Every AI platform is a **provider** following a plugin pattern:

1. **`UsageProvider` enum** (`Sources/TokenBarCore/Providers/Providers.swift`) -- add new providers here
2. **Provider folder** (`Sources/TokenBarCore/Providers/<Name>/`) with a descriptor and fetch strategies
3. **`ProviderDescriptor`** -- registry entry defining metadata, branding, token cost config, fetch plan, CLI config. Uses `@ProviderDescriptorRegistration` and `@ProviderDescriptorDefinition` macros for auto-registration.
4. **Fetch strategies** -- implement `ProviderFetchStrategy` protocol. Types include OAuth, Web Cookies, CLI PTY, API Token, Local Probe. Strategies compose into a pipeline with fallback.

### Data Flow

```
UsageStore (refresh orchestration)
  -> UsageFetcher (per-provider)
    -> ProviderDescriptor.fetch() (strategy pipeline)
      -> ProviderFetchStrategy.fetch() (OAuth/cookies/CLI/API)
        -> UsageSnapshot (usage + identity data)
          -> MenuCardView + IconRenderer (UI)
```

### Key Data Models

- **`UsageSnapshot`** -- provider's usage data: primary/secondary/tertiary rate windows, provider cost, identity
- **`RateWindow`** -- usage meter: usedPercent, windowMinutes, resetsAt
- **`ProviderDescriptor`** -- source of truth for a provider's configuration and behavior
- **`TokenBarConfig`** -- user config persisted at `~/.tokenbar/config.json` with migration support

### UI Patterns

- Prefer `@Observable` with `@State` / `@Bindable`. Do not use `ObservableObject`, `@ObservedObject`, or `@StateObject`.
- Favor macOS 15+ APIs when refactoring.
- Keep provider data siloed: never display identity/plan fields sourced from a different provider.

## Testing

Tests live in `Tests/TokenBarTests/` (140+ files). Convention: `FeatureNameTests` class with `test_caseDescription` methods.

```bash
swift test                                        # All tests
swift test --filter TTYIntegrationTests           # Integration tests
LIVE_TEST=1 swift test --filter LiveAccountTests  # Live tests (needs credentials)
```

## Adding a New Provider

1. Add case to `UsageProvider` enum in `Providers.swift`
2. Create folder `Sources/TokenBarCore/Providers/NewProvider/`
3. Define `NewProviderDescriptor.swift` with `@ProviderDescriptorRegistration` / `@ProviderDescriptorDefinition`
4. Implement fetch strategies conforming to `ProviderFetchStrategy`
5. Add tests in `Tests/TokenBarTests/`
6. Document in `docs/newprovider.md`

## Important Conventions

- Claude CLI status line is custom and user-configurable; never rely on it for usage parsing.
- Cookie imports: default to Chrome-only when possible to avoid other browser prompts.
- Do not add dependencies or tooling without confirmation.
- Commit messages: short imperative clauses (e.g., "Improve usage probe", "Fix icon dimming").
- Release script must run in foreground -- do not background it.

## Fork Management

This fork preserves providers that upstream removed (e.g., Augment). Multi-upstream scripts exist for selective syncing:

```bash
./Scripts/check_upstreams.sh upstream   # Monitor upstream changes
./Scripts/review_upstream.sh upstream   # Deep-dive into upstream commits
```

See `docs/UPSTREAM_STRATEGY.md` for full multi-upstream workflow.
