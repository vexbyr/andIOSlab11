import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw11_notes_vault/main.dart';
import 'package:lw11_notes_vault/models/note_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Builds the app the same way main() does, using fake (in-memory) storage.
Future<SharedPreferences> pumpApp(
  WidgetTester tester,
  Map<String, Object> saved,
) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(NotesVaultApp(
    prefs: prefs,
    initialDarkMode: prefs.getBool(kThemeKey) ?? false,
  ));
  return prefs;
}

void main() {
  test('NoteItem survives toJson -> fromJson', () {
    final note = NoteItem(id: '1', title: 'Milk', dateText: 'today');
    final copy = NoteItem.fromJson(
      jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
    );
    expect(copy.title, 'Milk');
    expect(copy.isCompleted, false);
  });

  testWidgets('first launch shows fallbacks', (tester) async {
    await pumpApp(tester, {});
    expect(find.text('Hello, Guest User!'), findsOneWidget);
    expect(find.text('No notes yet. Add your first note above!'),
        findsOneWidget);
  });

  testWidgets('add, toggle, delete and theme are saved', (tester) async {
    final prefs = await pumpApp(tester, {});

    // Add two notes: the newest must be first.
    await tester.enterText(find.widgetWithText(TextField, 'New note'), 'A');
    await tester.tap(find.byTooltip('Add note'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'New note'), 'B');
    await tester.tap(find.byTooltip('Add note'));
    await tester.pump();

    List<dynamic> saved() => jsonDecode(prefs.getString(kNotesKey)!);
    expect(saved().map((n) => n['title']), ['B', 'A']);

    // Toggle the first note.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(saved().first['isCompleted'], true);

    // Delete it.
    await tester.tap(find.byTooltip('Delete note').first);
    await tester.pump();
    expect(saved().map((n) => n['title']), ['A']);

    // Dark mode switch.
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(prefs.getBool(kThemeKey), true);

    // Username.
    await tester.enterText(
        find.widgetWithText(TextField, 'Display name'), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(prefs.getString(kUserNameKey), 'Alex');
    expect(find.text('Hello, Alex!'), findsOneWidget);
  });

  testWidgets('cold restart restores everything', (tester) async {
    await pumpApp(tester, {
      kThemeKey: true,
      kUserNameKey: 'Alex',
      kNotesKey: jsonEncode([
        {'id': '2', 'title': 'Second', 'dateText': 'd', 'isCompleted': true},
        {'id': '1', 'title': 'First', 'dateText': 'd'}, // no isCompleted
      ]),
    });
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Hello, Alex!'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('broken JSON on disk does not crash', (tester) async {
    await pumpApp(tester, {kNotesKey: 'not json'});
    expect(find.text('No notes yet. Add your first note above!'),
        findsOneWidget);
  });
}
