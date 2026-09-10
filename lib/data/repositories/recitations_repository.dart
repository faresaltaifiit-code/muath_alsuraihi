import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/surah_model.dart';

class RecitationsRepository {
  /// قائمة مضمنة في IPA؛ لا تحتاج اتصالًا بالإنترنت.
  Future<List<SurahModel>> getSurahs() async {
    final source = await rootBundle.loadString('assets/data/recitations_fallback.json');
    final root = jsonDecode(source) as Map<String, dynamic>;
    final rawSurahs = root['surahs'] as List<dynamic>? ?? [];
    return rawSurahs
        .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }
}

