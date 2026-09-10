import 'package:flutter/foundation.dart';

import '../data/models/surah_model.dart';
import '../data/repositories/recitations_repository.dart';

class RecitationsProvider extends ChangeNotifier {
  RecitationsProvider({RecitationsRepository? repository})
      : _repository = repository ?? RecitationsRepository();

  final RecitationsRepository _repository;
  List<SurahModel> _surahs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SurahModel> get surahs => List.unmodifiable(_surahs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _surahs = await _repository.getSurahs();
    } catch (_) {
      _errorMessage = 'تعذر قراءة قائمة التلاوات. حاول مرة أخرى لاحقًا.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

