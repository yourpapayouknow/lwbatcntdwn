# TrollStore Device Acceptance

## Supported Target

- iOS/iPadOS 15.0–16.6.1 or 16.7 RC with TrollStore.
- arm64 device.
- Developer Mode enabled where the device requires it.

## Install

1. Copy `build/LowBatCountdown-1.0.1.tipa` to the device.
2. Share/open the file with TrollStore and install it.
3. Open **低电量倒计时** once.
4. Keep **监控服务** enabled, then choose the desired trigger percentage and countdown duration.
5. After every full device reboot, open the app once to restore monitoring. TrollStore cannot install this helper as a boot launch daemon.

## Immediate Overlay Test

1. Disconnect the charger.
2. Open **低电量倒计时** and confirm the status says the monitor process started.
3. Tap **测试不可关闭弹窗** and accept the warning.
4. Verify the dark full-screen overlay appears above the Home Screen and another app.
5. Verify there is no close button or backdrop/swipe dismissal.
6. Verify the seconds reach zero and the overlay remains.
7. Connect power and verify the overlay disappears within one second.

## Real Low-Battery Test

1. Set the trigger to a value above the current battery percentage, within the supported 1–20% range, or drain the device to the configured threshold.
2. Leave the settings app and use another app.
3. Verify the overlay appears when battery percentage becomes equal to or lower than the configured threshold.
4. Verify duplicate battery notifications do not restart the countdown.
5. Verify connecting power is the only normal exit.

## Recovery

- Normal recovery: connect a charger.
- Emergency recovery if private battery APIs or window hosting misbehave: reboot the device. Monitoring does not auto-start after a full reboot until the settings app is opened again.
- Uninstall through TrollStore only after the overlay is no longer visible.

## Acceptance Record

- Device model: not supplied
- iOS version: not supplied
- TrollStore version: not supplied
- Immediate overlay test: passed per user report
- Real low-battery trigger: passed per user report
- Charging dismissal: not separately reported
