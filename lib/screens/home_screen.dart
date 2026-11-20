import 'dart:convert'; // jsonEncode / jsonDecode

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // storage keys
import '../models/note_item.dart';

// The only screen of the app: header, settings, add-note form and notes list.
class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs; // already loaded in main()
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged; // saving happens in NotesVaultApp

  const HomeScreen({
    super.key,
    required this.prefs,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  String _displayName = 'Guest User';
  List<NoteItem> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadNotes();
  }

  @override
  void dispose() {
    // Free the controllers when the screen is removed.
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ---------------- Username ----------------

  // Read the saved name. First launch -> null -> fallback 'Guest User'.
  void _loadUserName() {
    final savedName = widget.prefs.getString(kUserNameKey);
    _displayName = savedName ?? 'Guest User';
    _nameController.text = savedName ?? '';
  }

  Future<void> _saveUserName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return; // nothing to save

    // Update the UI first (we use context only BEFORE the await).
    setState(() => _displayName = name);
    FocusScope.of(context).unfocus(); // hide the keyboard
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Name saved')));

    // Then save to disk.
    await widget.prefs.setString(kUserNameKey, name);
  }

  // ---------------- Notes ----------------

  // Load the notes: String from disk -> jsonDecode -> List<NoteItem>.
  void _loadNotes() {
    final String? rawJson = widget.prefs.getString(kNotesKey);

    // First launch: nothing saved yet (null), so the list stays empty.
    if (rawJson != null) {
      // Parsing is risky: if the saved text is broken, don't crash.
      try {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _notes = decoded
            .map((item) => NoteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Could not read notes: $e');
        _notes = []; // show an empty list instead
      }
    }
  }

  // Save the WHOLE list: List<NoteItem> -> List<Map> -> one JSON String.
  Future<void> _saveNotes() async {
    final String jsonString =
        jsonEncode(_notes.map((note) => note.toJson()).toList());
    await widget.prefs.setString(kNotesKey, jsonString);
  }

  Future<void> _addNote() async {
    final title = _noteController.text.trim();
    if (title.isEmpty) return; // ignore empty notes

    final now = DateTime.now();
    final newNote = NoteItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      // e.g. "21.11.2026 14:05"
      dateText: '${now.day}.${now.month}.${now.year} '
          '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );

    setState(() {
      _notes.insert(0, newNote); // newest note goes to the START of the list
      _noteController.clear();
    });
    await _saveNotes();
  }

  Future<void> _toggleNote(NoteItem note, bool? value) async {
    setState(() => note.isCompleted = value ?? false);
    await _saveNotes();
  }

  Future<void> _deleteNote(NoteItem note) async {
    setState(() => _notes.remove(note));
    await _saveNotes(); // save immediately after deleting
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes Vault')),
      // SafeArea keeps content away from notches and system bars.
      body: SafeArea(
        // One scrolling ListView, so nothing overflows in landscape
        // or when the keyboard is open.
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header with the saved username.
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  'Hello, $_displayName!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            // Dark mode switch (saved in main.dart).
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
            ),

            // Username field + Save button.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveUserName,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // New note field + add button.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'New note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addNote,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add note',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Empty state or the list of notes.
            if (_notes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No notes yet. Add your first note above!',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._notes.map(
                (note) => Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: note.isCompleted,
                      onChanged: (value) => _toggleNote(note, value),
                    ),
                    title: Text(note.title),
                    subtitle: Text(note.dateText),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete note',
                      onPressed: () => _deleteNote(note),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
