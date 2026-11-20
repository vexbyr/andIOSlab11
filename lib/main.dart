import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';

// Storage keys, kept in one place so we never mistype them.
const String kThemeKey = 'app_theme_dark_mode';
const String kUserNameKey = 'user_display_name';
const String kNotesKey = 'notes_json';

// main() is async because we read from disk BEFORE the first frame.
Future<void> main() async {
  // Needed before using plugins (SharedPreferences talks to native
  // Android/iOS code through platform channels) when runApp() hasn't run yet.
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings from disk.
  final prefs = await SharedPreferences.getInstance();

  // On the very first install there is no value yet (null), so we use ?? false.
  final isDark = prefs.getBool(kThemeKey) ?? false;

  // Pass the saved theme into the app, so the first frame is already the
  // correct theme (no white flash in dark mode).
  runApp(NotesVaultApp(prefs: prefs, initialDarkMode: isDark));
}

class NotesVaultApp extends StatefulWidget {
  final SharedPreferences prefs;
  final bool initialDarkMode;

  const NotesVaultApp({
    super.key,
    required this.prefs,
    required this.initialDarkMode,
  });

  @override
  State<NotesVaultApp> createState() => _NotesVaultAppState();
}

class _NotesVaultAppState extends State<NotesVaultApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode; // value loaded in main()
  }

  // Called by the Switch on the home screen.
  Future<void> _toggleTheme(bool value) async {
    setState(() => _isDarkMode = value); // update the UI right away
    await widget.prefs.setBool(kThemeKey, value); // then save to disk
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        prefs: widget.prefs,
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
