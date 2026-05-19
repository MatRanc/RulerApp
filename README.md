# Ruler App

A macOS ruler app. Put a physical object against the screen and read its dimensions off the ruler. Resize the window to whatever you need; click the green button to go fullscreen for measuring larger things.

## Build & run

```
brew install xcodegen   # one-time, if you don't have it
xcodegen generate
open RulerApp.xcodeproj
```

Then ⌘R in Xcode.

## Hotkeys

- **U** — cycle unit: cm → inches → both
- **G** — toggle 1cm grid
- **C** — recalibrate the display the window is currently on

The same actions are available as buttons in the bottom-right corner.

## Calibration

On first launch you'll be walked through calibration for any uncalibrated displays. Hold a credit card (long edge, 85.6 mm) flush against the on-screen line and drag the slider until they match. Calibration is stored per display (keyed by `CGDisplayCreateUUIDFromDisplayID`) and picked up automatically when you move the window between displays. Hit **Calibrate** in the controls strip (or **C**) any time to redo it.
