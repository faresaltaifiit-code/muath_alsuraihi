import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/surah_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorite_surahs';
  final Map<String, SurahModel> _favorites = {};

  List<SurahModel> get favorites => _favorites.values.toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  bool contains(SurahModel surah) => _favorites.containsKey(_keyFor(surah));

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    for (final value in preferences.getStringList(_key) ?? []) {
      try {
        final surah = SurahModel.fromJson(jsonDecode(value) as Map<String, dynamic>);
        _favorites[_keyFor(surah)] = surah;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> toggle(SurahModel surah) async {
    final key = _keyFor(surah);
    if (_favorites.containsKey(key)) {
      _favorites.remove(key);
    } else {
      _favorites[key] = surah;
    }
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      _favorites.values.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  String _keyFor(SurahModel surah) => '${surah.number}:${surah.id}';
}

