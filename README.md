# Mikan (蜜柑)

Mikan is an iOS app built with SwiftUI and WidgetKit for practicing Japanese Kanji daily. It includes interactive flashcards covering JLPT levels N5 through N1, along with Home Screen and Lock Screen widgets that update throughout the day.

## How it works

- **Flashcard Study:** Tap on any card to flip it and view the stroke count, English meanings, On'yomi & Kun'yomi readings, and vocabulary examples.
- **JLPT Levels & Favorites:** Filter cards by difficulty level (N5 to N1) or save difficult characters to your favorites list.
- **Home & Lock Screen Widgets:** Displays a kanji directly on your screen using WidgetKit. Tapping the widget deep-links straight into the app to that specific kanji.
- **Customizable Intervals:** Choose how often the widget rotates (hourly, every 6h/12h, daily, or custom hours) and choose between sequential or random order.

## Tech Details

- **SwiftUI** for the entire interface and animations.
- **WidgetKit** supporting multiple sizes: Home Screen (`systemSmall`) and Lock Screen (rectangular, circular, inline).
- **App Groups** (`UserDefaults`) to share data and sync settings between the app and the widget.
- **Local JSON:** Over 1,000 kanji entries bundled locally in `kanji.json`.

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

1. Clone the repo:
   ```bash
   git clone https://github.com/Aniapric/Mikan.git
   ```
2. Open `Mikan.xcodeproj` in Xcode.
3. Select the `Mikan` scheme and run (`Cmd + R`).

## Contributors

Developed by **Ania** ([@Aniapric](https://github.com/Aniapric)) and **Rareș** ([@Rareshh](https://github.com/Rareshh)).
