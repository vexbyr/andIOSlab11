// A single note in our Notes Vault.
// SharedPreferences can only store simple types (bool, int, double, String,
// List<String>), so we convert each note to a Map and back (JSON).
class NoteItem {
  final String id; // unique id (we use the creation time in milliseconds)
  final String title; // the note text
  final String dateText; // human-readable creation date, e.g. "21.11.2026 14:05"
  bool isCompleted; // checkbox state (not final, because the user toggles it)

  NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    this.isCompleted = false,
  });

  // Model -> Map. jsonEncode() can turn this Map into a JSON string.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateText': dateText,
        'isCompleted': isCompleted,
      };

  // Map -> Model. Used after jsonDecode() when we load from disk.
  // 'as bool? ?? false' protects us if the field is missing (old data).
  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      dateText: json['dateText'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
