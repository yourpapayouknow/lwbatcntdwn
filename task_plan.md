# Low Battery Countdown TIPA Plan

## Goal

Build an Objective-C/UIKit TrollStore package for iOS 15–16 that shows a system-wide, non-dismissible low-battery countdown overlay. The threshold and countdown are configurable; once the countdown reaches zero, the overlay stays until power is connected.

## Success Criteria

- The package builds reproducibly as a `.tipa`.
- Battery-state logic triggers at the configured threshold and clears only when charging.
- The overlay intercepts dismissal attempts and remains visible after countdown completion.
- Logic tests cover threshold, duplicate events, countdown completion, charging, empty/default settings, and boundary values.
- A real-device checklist demonstrates the alert on an iOS 15–16 TrollStore device.

## Assumptions Confirmed

- Target: iOS 15–16 with TrollStore.
- Stack: Objective-C and UIKit.
- UI: dark translucent full-screen mask, centered frosted card, red warning accent, system typography, no close control or flashing.
- Behavior: configurable threshold/countdown; remain blocked after zero until charging.

## Phases

1. **Repository and design baseline** — complete
   - Create Git baseline, planning files, DESIGN.md, and lint the design file.
2. **Reference research and feasibility proof** — complete
   - Find and clone only relevant TrollStore, battery-monitor, background, and SpringBoard-overlay references.
   - Record source, reuse candidate, integration plan, and adaptation level in `refrence/refrence.md`.
   - Prove whether TrollStore-only system-wide presentation is feasible on iOS 15–16 before full implementation.
3. **Minimal implementation** — in progress
   - Reuse the selected native approach for battery observation, configuration, background operation, and overlay presentation.
4. **Tests and package build** — pending
   - Run unit/logic tests, static checks, build, sign/package as `.tipa`, and inspect entitlements/bundle contents.
5. **Device handoff** — pending
   - Provide install and low-battery validation steps, known version limitations, and recovery instructions.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Working directory was not a Git repository | 1 | Initialized Git and created an empty baseline commit before project changes. |
| Design depth prompt returned no selection | 1 | Reissued the same design question and received the selected answer. |
| DESIGN.md used an unsupported `tokens` wrapper | 1 | Read the official CLI specification and moved values under supported top-level token groups. |
| DESIGN.md component sub-token names were invalid | 1 | Replaced them with names accepted by design.md v0.4.0 and referenced the semantic colors through components. |
| `autocli` Chrome extension did not connect | 1 | Recorded the timeout and switched to read-only web search with primary-source filtering. |
