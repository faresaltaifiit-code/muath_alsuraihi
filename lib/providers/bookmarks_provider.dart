import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkEntry {
  const BookmarkEntry({required this.surahId, required this.positionMs, required this.label, required this.createdAt});
  final String surahId;
  final int positionMs;
  final String label;
  final int createdAt;
  Map<String, Object> toJson() => {'surah_id': surahId, 'position_ms': positionMs, 'label': label, 'created_at': createdAt};
  factory BookmarkEntry.fromJson(Map<String, dynamic> json) => BookmarkEntry(
        surahId: json['surah_id'] as String,
        positionMs: (json['position_ms'] as num).toInt(),
        label: json['label'] as String? ?? '',
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      );
}

class BookmarksProvider extends ChangeNotifier {
  static const _key = 'surah_bookmarks_v1';
  List<BookmarkEntry> _items = const [];
  List<BookmarkEntry> forSurah(String id) => _items.where((item) => item.surahId == id).toList()..sort((a, b) => a.positionMs.compareTo(b.positionMs));
  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return;
    try { _items = (jsonDecode(value) as List).whereType<Map<String, dynamic>>().map(BookmarkEntry.fromJson).toList(); } catch (_) { _items = const []; }
    notifyListeners();
  }
  Future<void> add(String surahId, Duration position) async {
    final current = forSurah(surahId);
    if (current.length >= 100) return;
    _items = [..._items, BookmarkEntry(surahId: surahId, positionMs: position.inMilliseconds, label: '', createdAt: DateTime.now().millisecondsSinceEpoch)];
    await _save();
  }
  Future<void> remove(BookmarkEntry item) async { _items = _items.where((entry) => entry.createdAt != item.createdAt).toList(); await _save(); }
  Future<void> rename(BookmarkEntry item, String label) async { _items = _items.map((entry) => entry.createdAt == item.createdAt ? BookmarkEntry(surahId: entry.surahId, positionMs: entry.positionMs, label: label, createdAt: entry.createdAt) : entry).toList(); await _save(); }
  Future<void> _save() async { await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(_items.map((item) => item.toJson()).toList())); notifyListeners(); }
}
