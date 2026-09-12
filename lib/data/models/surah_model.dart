class SurahModel {
  const SurahModel({
    required this.id,
    required this.number,
    required this.name,
    required this.reciterName,
    required this.durationSeconds,
    required this.durationText,
    required this.audioPath,
    required this.available,
    required this.fileSizeBytes,
    required this.fileSizeText,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) => SurahModel(
        id: json['id'] as String? ?? 'surah_${(json['number'] as num?)?.toInt() ?? 0}',
        number: (json['number'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? json['title'] as String? ?? '',
        reciterName: json['reciter_name'] as String? ?? 'الشيخ معاذ بن ماجد السريحي',
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
        durationText: json['duration_text'] as String? ?? '',
        audioPath: json['audio_path'] as String? ?? '',
        available: json['available'] as bool? ?? true,
        fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
        fileSizeText: json['file_size_text'] as String? ?? '',
      );

  final String id;
  final int number;
  final String name;
  final String reciterName;
  final int durationSeconds;
  final String durationText;
  final String audioPath;
  final bool available;
  final int fileSizeBytes;
  final String fileSizeText;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'reciter_name': reciterName,
        'duration_seconds': durationSeconds,
        'duration_text': durationText,
        'audio_path': audioPath,
        'available': available,
        'file_size_bytes': fileSizeBytes,
        'file_size_text': fileSizeText,
      };
}

