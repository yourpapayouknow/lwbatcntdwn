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
3. **Minimal implementation** — complete
   - Reuse the selected native approach for battery observation, configuration, background operation, and overlay presentation.
4. **Tests and package build** — complete
   - Run unit/logic tests, static checks, build, sign/package as `.tipa`, and inspect entitlements/bundle contents.
5. **Device handoff** — complete
   - Provide install and low-battery validation steps, known version limitations, and recovery instructions.
   - User reported successful real-device low-battery overlay testing.
6. **Small-screen and icon follow-up** — complete
   - Keep the monitor switch inside its card on compact-width devices.
   - Add a complete iPhone/iPad App Icon asset catalog and rebuild the `.tipa`.
7. **Bundle identifier correction** — complete
   - Replace every runtime namespace with `com.iwmeiagent.lowbatcntdwn`.
   - Preserve intentional coexistence with the older `com.codex.lowbat` build.
   - Rebuild and inspect version 1.0.2.

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Working directory was not a Git repository | 1 | Initialized Git and created an empty baseline commit before project changes. |
| Design depth prompt returned no selection | 1 | Reissued the same design question and received the selected answer. |
| DESIGN.md used an unsupported `tokens` wrapper | 1 | Read the official CLI specification and moved values under supported top-level token groups. |
| DESIGN.md component sub-token names were invalid | 1 | Replaced them with names accepted by design.md v0.4.0 and referenced the semantic colors through components. |
| `autocli` Chrome extension did not connect | 1 | Recorded the timeout and switched to read-only web search with primary-source filtering. |
| `_NSGetExecutablePath` was undeclared during the first iOS compile | 1 | Added its official `<mach-o/dyld.h>` declaration to the unified project header. |
| `UIButton.contentEdgeInsets` is deprecated on the iOS 15 target | 1 | Replaced legacy button styling with the native iOS 15 `UIButtonConfiguration` API. |
| No iOS device is connected for TrollStore runtime validation | 1 | Continue with build/static/logic verification and leave real-device acceptance explicitly pending. |
| Monitor switch overflows its card on small screens | 1 | Root cause confirmed as equal default compression priorities between a long wrapping label and fixed-size switch. |
| Installed app has an empty icon | 1 | Root cause confirmed: no icon catalog, bundle icon declaration, or icon resource existed in the package. |
| `plutil` rejected Asset Catalog `Contents.json` | 1 | The files are JSON rather than XML plists; validate them with a JSON parser while retaining `actool` as the authoritative asset compiler. |
