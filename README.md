# LW11 - Offline-First Notes & Settings Vault

Laboratory Work 11 for the mobile development course (Flutter, Android and iOS).

## What the app does

- **Dark mode** - a switch that changes the theme. The choice is saved and loaded
  in `main()` before `runApp()`, so the app opens in the right theme without a white flash.
- **Username** - type your name and press Save. It is shown in the header.
  If no name is saved yet, it shows "Guest User".
- **Notes** - add a note (it goes to the top of the list), mark it done with a checkbox,
  or delete it. The whole list is saved as JSON (`jsonEncode` / `jsonDecode`).

Everything is stored on the device with the `shared_preferences` package,
so the data is still there after the app is fully closed and opened again.

Storage keys: `app_theme_dark_mode`, `user_display_name`, `notes_json`.

## Project structure

```
lib/
  main.dart                 - loads saved settings, starts the app, theme
  models/note_item.dart     - NoteItem model with toJson() and fromJson()
  screens/home_screen.dart  - the main screen (username, switch, notes list)
test/
  widget_test.dart          - tests for saving and loading
```

## How to run

```
flutter pub get
flutter run
```

To run the tests:

```
flutter test
```
