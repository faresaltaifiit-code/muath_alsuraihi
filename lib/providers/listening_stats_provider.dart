import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/surah_model.dart';

enum DailyWirdType { surahs, minutes, juz }

class ListeningStatsProvider extends ChangeNotifier {
  static const _key = 'local_listening_stats_v1';
  static const _enabledKey = 'local_listening_stats_enabled';
  static const _goalTypeKey = 'daily_wird_type';
  static const _goalKey = 'daily_wird_goal';

  bool _enabled = true;
  int _totalMilliseconds = 0;
  final Map<String, int> _dayMilliseconds = <String, int>{};
  final Map<String, int> _playCounts = <String, int>{};
  final Map<String, int> _completedCounts = <String, int>{};
  final Map<String, _StatRecitation> _recitations = <String, _StatRecitation>{};
  DailyWirdType _goalType = DailyWirdType.surahs;
  int _goal = 3;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get isLoaded => _loaded;
  int get totalListeningMinutes =>
      _totalMilliseconds ~/ Duration.millisecondsPerMinute;
  int get completedSurahs => _completedCounts.values.fold(0, (a, b) => a + b);
  DailyWirdType get goalType => _goalType;
  int get goal => _goal;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_enabledKey) ?? true;
    _goalType = switch (preferences.getString(_goalTypeKey)) {
      'minutes' => DailyWirdType.minutes,
      'juz' => DailyWirdType.juz,
      _ => DailyWirdType.surahs,
    };
    _goal = preferences.getInt(_goalKey) ??
        (_goalType == DailyWirdType.minutes
            ? 15
            : _goalType == DailyWirdType.juz
                ? 1
                : 3);
    final stored = preferences.getString(_key);
    if (stored != null) {
      try {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        _totalMilliseconds = (data['total_ms'] as num?)?.toInt() ?? 0;
        _restoreNumberMap(data['days'], _dayMilliseconds);
        _restoreNumberMap(data['plays'], _playCounts);
        _restoreNumberMap(data['completed'], _completedCounts);
        final recitations =
            data['recitations'] as Map<String, dynamic>? ?? const {};
        for (final entry in recitations.entries) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            _recitations[entry.key] = _StatRecitation.fromJson(value);
          }
        }
      } catch (_) {
        // Bad local data is ignored; playback must never depend on statistics.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);
  }

  Future<void> setGoal(DailyWirdType type, int value) async {
    _goalType = type;
    _goal = value.clamp(1, 120);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_goalTypeKey, type.name);
    await preferences.setInt(_goalKey, _goal);
  }

  Future<void> recordPlay(SurahModel surah) async {
    if (!_enabled) return;
    final id = surah.audioPath;
    _playCounts[id] = (_playCounts[id] ?? 0) + 1;
    _recitations[id] =
        _StatRecitation(name: surah.name, playedAt: DateTime.now());
    notifyListeners();
    await _save();
  }

  Future<void> recordListening(SurahModel surah, Duration amount) async {
    if (!_enabled || amount <= Duration.zero) return;
    final milliseconds = amount.inMilliseconds;
    _totalMilliseconds += milliseconds;
    final day = _dayKey(DateTime.now());
    _dayMilliseconds[day] = (_dayMilliseconds[day] ?? 0) + milliseconds;
    _recitations[surah.audioPath] =
        _StatRecitation(name: surah.name, playedAt: DateTime.now());
    notifyListeners();
    await _save();
  }

  Future<void> recordCompleted(SurahModel surah) async {
    if (!_enabled) return;
    final id = surah.audioPath;
    _completedCounts[id] = (_completedCounts[id] ?? 0) + 1;
    _recitations[id] =
        _StatRecitation(name: surah.name, playedAt: DateTime.now());
    notifyListeners();
    await _save();
  }

  int dayMinutes(DateTime day) =>
      (_dayMilliseconds[_dayKey(day)] ?? 0) ~/ Duration.millisecondsPerMinute;

  int get todayMinutes => dayMinutes(DateTime.now());

  int get todayCompleted => _completedCounts.entries
      .where((entry) =>
          _recitations[entry.key]?.playedAt != null &&
          _sameDay(_recitations[entry.key]!.playedAt, DateTime.now()))
      .fold(0, (sum, entry) => sum + entry.value);

  int get dailyProgress => switch (_goalType) {
        DailyWirdType.surahs => todayCompleted,
        DailyWirdType.minutes => todayMinutes,
        DailyWirdType.juz => todayMinutes ~/ 30,
      };

  double get dailyProgressFraction =>
      (dailyProgress / _goal).clamp(0, 1).toDouble();

  List<DailyListeningTotal> get lastSevenDays {
    final today = DateTime.now();
    return List<DailyListeningTotal>.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index));
      return DailyListeningTotal(day: day, minutes: dayMinutes(day));
    });
  }

  List<MostListenedRecitation> get mostListened {
    final items = _playCounts.entries.map((entry) {
      final item = _recitations[entry.key];
      return MostListenedRecitation(
        name: item?.name ?? 'تلاوة',
        count: entry.value,
        playedAt: item?.playedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList()
      ..sort((a, b) => b.count != a.count
          ? b.count.compareTo(a.count)
          : b.playedAt.compareTo(a.playedAt));
    return items.take(3).toList();
  }

  Future<void> clear() async {
    _totalMilliseconds = 0;
    _dayMilliseconds.clear();
    _playCounts.clear();
    _completedCounts.clear();
    _recitations.clear();
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        _key,
        jsonEncode({
          'total_ms': _totalMilliseconds,
          'days': _dayMilliseconds,
          'plays': _playCounts,
          'completed': _completedCounts,
          'recitations':
              _recitations.map((key, value) => MapEntry(key, value.toJson())),
        }));
  }

  static void _restoreNumberMap(Object? value, Map<String, int> target) {
    if (value is! Map<String, dynamic>) return;
    for (final entry in value.entries) {
      if (entry.value is num) target[entry.key] = (entry.value as num).toInt();
    }
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static bool _sameDay(DateTime one, DateTime two) =>
      one.year == two.year && one.month == two.month && one.day == two.day;
}

class DailyListeningTotal {
  const DailyListeningTotal({required this.day, required this.minutes});
  final DateTime day;
  final int minutes;
}

class MostListenedRecitation {
  const MostListenedRecitation(
      {required this.name, required this.count, required this.playedAt});
  final String name;
  final int count;
  final DateTime playedAt;
}

class _StatRecitation {
  const _StatRecitation({required this.name, required this.playedAt});
  final String name;
  final DateTime playedAt;
  Map<String, dynamic> toJson() =>
      {'name': name, 'played_at': playedAt.millisecondsSinceEpoch};
  factory _StatRecitation.fromJson(Map<String, dynamic> value) =>
      _StatRecitation(
        name: value['name'] as String? ?? 'تلاوة',
        playedAt: DateTime.fromMillisecondsSinceEpoch(
            (value['played_at'] as num?)?.toInt() ?? 0),
      );
}
