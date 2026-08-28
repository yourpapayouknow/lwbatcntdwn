# Findings

## Confirmed Requirements

- Product mood: minimal jailbreak utility.
- Colors: dark gray/black translucent surfaces with red warning emphasis.
- Typography: San Francisco with a large bold countdown.
- Layout: full-screen touch-blocking mask and centered compact card.
- Depth: strong background dimming, dark frosted card, subtle border.
- Shapes: 18–22 pt card radius and capsule progress indicator.
- Components: warning icon, current battery, countdown, progress, concise explanation, no close control.
- Do: high contrast, short copy, stable motion.
- Do not: close button, flashing, decorative gradients, extra diagnostic data.

## Research Notes

- `autocli` could not connect to its Chrome extension within 30 seconds, so it returned no GitHub search results. Continue with read-only web search and primary sources only.
- The official TrollStore release history exposes a root helper and a persistence helper installation path, but the search result does not establish arbitrary SpringBoard code injection or a global overlay API.
- TrollFools provides in-place dylib injection for removable system apps and TrollStore/decrypted apps across TrollStore-supported iOS versions. Its documented target list does not include SpringBoard, so it is not yet proof of a system-wide overlay route.
- Public `UIDevice` battery notifications are sufficient for percentage/state in a foreground process; older `UIDeviceListener`/IOKit examples are unnecessary unless background delivery or more precise data is proven missing.
- Apple's open-source PowerManagement code confirms the battery subsystem publishes current capacity and charging state, and identifies private battery-data entitlements. It is evidence for the data source, not for UI presentation.
- Search did not find a primary-source example showing that a standalone TrollStore app can create a non-dismissible cross-application overlay. Feasibility remains unproven.
- The official TrollStore README is decisive about limits: TrollStore cannot platformize binaries, spawn launch daemons, or inject tweaks into system processes. Therefore a SpringBoard tweak/daemon cannot be bundled as a TrollStore-only solution for all iOS 15–16.
- The same official README confirms arbitrary entitlements, unsandboxed apps, bundled helper binaries, and root helper spawning. These capabilities may support a standalone overlay technique but do not guarantee continuous execution.
- Letterpress is a primary-source TrollStore app claiming a system-wide floating overlay. It is the strongest candidate reference and must be inspected before rejecting a TrollStore-only overlay.
- SpringBoard injection solutions such as Serotonin/Bootstrap add an external exploit/bootstrap requirement and cover narrower versions (notably iOS 16), so they violate the selected TrollStore-only deployment target.
- App-level injectors (TrollFools/Azula) inject into selected apps, not into SpringBoard; they cannot guarantee an overlay over every foreground process.
- Letterpress supports iOS 15+, installs as a `.tipa`, and documents lock-screen plus screenshot behavior. It directly matches the presentation layer and is MIT-licensed, though it is EOL.
- Letterpress credits `SkyLightWindow`, but the currently published SkyLightWindow repository documents a macOS-only implementation. The actual iOS overlay code therefore needs to be located inside Letterpress rather than inferred from the current dependency README.
- TrollStore official documentation confirms installed apps may carry arbitrary entitlements; this is likely how Letterpress obtains an elevated window scene. The exact entitlement/API combination must be copied only after source inspection.
- TrollSpeed documents the exact standalone architecture needed here: a TrollStore settings app spawns a separate HUD process as root, and that HUD carries entitlements copied from `assistivetouchd` to display and persist global windows. It also warns that root spawning is needed to survive device unlock.
- This HUD-process approach avoids the impossible paths listed by TrollStore: it is neither a launch daemon nor SpringBoard injection. It is currently the best-fit implementation method.
- Background reliability is still a device-level concern: the helper can be killed or fail after reboot, and TrollStore cannot install a true launch daemon. The first release should require the user to enable/start the service after install/reboot unless a documented app-relaunch mechanism is found.
- Immortalizer-style process retention is not the preferred core because reports describe screen-off instability and it adds GPL injection complexity; the assistivetouchd-style HUD process already exists specifically for persistent global windows.
- The verified Lessica/TrollSpeed source registers an elevated window context through `SBSAccessibilityWindowHostingController`, sets a very high window level, marks the window as system/secure, and root-spawns the same executable with a `-hud` argument in a detached process group.
- Its entitlement list includes `com.apple.springboard.accessibility-window-hosting`, `com.apple.QuartzCore.displayable-context`, `com.apple.backboard.client`, `com.apple.private.persona-mgmt`, `com.apple.private.security.no-sandbox`, and `platform-application`. Additional HID/event entitlements are for forwarding touches; a blocking overlay may not need that entire surface.
- TrollSpeed is GPL, so it will be used only as a feasibility/API cross-check. The implementation should derive from Letterpress/TRHud if that subtree is MIT, avoiding license contamination and excess code.
- A misleading fork (`malikmohib/Trolstore`) was moved to `/tmp/lwbatcntdwn-untrusted-trolstore-ref` after its content failed provenance checks. The official `Lessica/TrollSpeed` clone replaced it.
- Local build decision: use `xcrun --sdk iphoneos clang` plus `ldid` and `zip`; no Theos installation or project dependency is necessary.

## Device Follow-up

- The user confirmed the low-battery overlay works on a real device.
- Small-screen switch overflow is isolated to the settings row's horizontal compression priorities; the HUD overlay and background monitor are unaffected.
- The empty installed icon is caused by the absence of an asset catalog and `CFBundleIcons` metadata.
