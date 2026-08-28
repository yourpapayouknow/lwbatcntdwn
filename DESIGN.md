---
version: alpha
name: Low Battery Countdown
description: Minimal system-level low-battery warning for iOS 15-16 TrollStore users.
colors:
  primary: "#08090B"
  surface: "rgba(27, 28, 31, 0.88)"
  text: "#F5F5F7"
  text-muted: "#A1A1A6"
  warning: "#FF453A"
typography:
  countdown:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: 72px
    fontWeight: 700
    lineHeight: 1
    fontFeature: "tnum"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.2
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.4
rounded:
  card: 20px
  capsule: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
components:
  blocking-overlay:
    backgroundColor: "{colors.primary}"
  warning-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.card}"
    padding: "{spacing.lg}"
  title:
    textColor: "{colors.text}"
    typography: "{typography.title}"
  countdown:
    textColor: "{colors.warning}"
    typography: "{typography.countdown}"
  explanation:
    textColor: "{colors.text-muted}"
    typography: "{typography.body}"
  progress:
    backgroundColor: "{colors.warning}"
    rounded: "{rounded.capsule}"
---

## Overview

Low Battery Countdown is a minimal jailbreak utility for TrollStore users on iOS 15–16. It should feel restrained, urgent, and trustworthy. The countdown is the visual focus; the interface must communicate a system-level interruption rather than a conventional application modal.

## Colors

- Use a near-black dimming layer over the entire screen.
- Use a dark translucent gray card surface with a subtle white border.
- Use off-white for primary text and muted gray for supporting text.
- Reserve warning red for the battery icon, countdown, and progress state.
- Do not use decorative gradients.

## Typography

- Use the San Francisco system font through UIKit system-font APIs.
- Render the countdown as the largest element with a bold weight and tabular numerals.
- Render the title at a medium size and semibold weight.
- Render battery percentage and explanation at regular weight with high legibility.
- Keep text concise and avoid all-caps paragraphs.

## Layout

- Cover the full display and safe-area edges with a touch-intercepting dimming layer.
- Center a compact card with 24 pt internal padding and a maximum width suitable for iPhone and iPad.
- Use an 8 pt base spacing rhythm.
- Keep the warning icon, battery value, countdown, progress, and explanation in a single vertical flow.
- Adapt width to compact and regular size classes without changing information order.
- On narrow screens, explanatory labels must wrap and yield horizontal space before fixed-size controls such as switches or value labels.

## Elevation & Depth

- Apply strong background dimming.
- Use a dark material blur for the card where supported, with an opaque dark fallback.
- Add a subtle one-pixel light border.
- Avoid pronounced drop shadows that make the surface look like a dismissible application alert.

## Shapes

- Use a 20 pt corner radius for the primary card.
- Use capsule geometry for the countdown progress track and fill.
- Keep iconography geometric and system-native.
- Do not use playful or irregular shapes.

## Components

- **Blocking overlay:** fills the display, intercepts touches, has no dismissal gesture, and remains visible after the timer reaches zero until charging is detected.
- **Warning card:** centered frosted surface containing all alert content.
- **Warning icon:** system battery or exclamation symbol tinted warning red.
- **Battery value:** current integer percentage.
- **Countdown:** large tabular seconds; at zero, replace time progression with a stable zero state.
- **Progress indicator:** capsule track whose red fill decreases with time and remains empty at zero.
- **Explanation:** short text telling the user to connect power; no close button or secondary action.
- **Settings:** native grouped controls for threshold and countdown duration with clear valid ranges.
- **Settings switch row:** keep the switch fully inside its card at all widths; the explanatory label wraps instead of pushing or compressing the switch.

## Do's and Don'ts

### Do

- Maintain strong contrast and short, direct copy.
- Use stable, subtle transitions only when the overlay appears or values update.
- Keep the countdown and charging instruction unambiguous.
- Respect safe areas, Dynamic Type where it does not undermine the countdown hierarchy, and reduce-motion settings.

### Don't

- Do not include a close button, swipe-to-dismiss gesture, or tappable backdrop dismissal.
- Do not flash, pulse continuously, or use aggressive color cycling.
- Do not add decorative gradients, illustrations, or unrelated diagnostics.
- Do not imply the countdown will dismiss the overlay; charging is the only exit condition.
