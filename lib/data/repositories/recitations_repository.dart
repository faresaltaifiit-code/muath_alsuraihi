import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/surah_model.dart';

class RecitationsRepository {
  /// قائمة مضمنة في IPA؛ لا تحتاج اتصالًا بالإنترنت.
  Future<RecitationsCatalog> getCatalog() async {
    final source = await rootBundle.loadString('assets/data/recitations_fallback.json');
    final root = jsonDecode(source) as Map<String, dynamic>;
    final rawSurahs = root['surahs'] as List<dynamic>? ?? [];
    final surahs = rawSurahs
        .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final rawSpecial = root['special_recitations'] as List<dynamic>? ?? [];
    final specialRecitations = rawSpecial
        .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return RecitationsCatalog(
      surahs: surahs,
      specialRecitations: specialRecitations,
    );
  }
}

class RecitationsCatalog {
  const RecitationsCatalog({
    required this.surahs,
    required this.specialRecitations,
  });

  final List<SurahModel> surahs;
  final List<SurahModel> specialRecitations;
}

