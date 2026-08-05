import 'package:cloud_firestore/cloud_firestore.dart';

enum EmotionType { joy, anger, sadness }

class DailyEmotionCard {
  final String id;
  final String userId;
  final EmotionType emotion;
  final String userMessage;
  final String? generatedImage;
  final String? generatedName;
  final DateTime createdAt;
  final int consecutiveDays;

  DailyEmotionCard({
    required this.id,
    required this.userId,
    required this.emotion,
    required this.userMessage,
    this.generatedImage,
    this.generatedName,
    required this.createdAt,
    this.consecutiveDays = 1,
  });

  String get emotionEmoji => switch (emotion) {
    EmotionType.joy => '😊',
    EmotionType.anger => '😠',
    EmotionType.sadness => '😢',
  };

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'emotion': emotion.name,
    'userMessage': userMessage,
    'generatedImage': generatedImage,
    'generatedName': generatedName,
    'createdAt': Timestamp.fromDate(createdAt),
    'consecutiveDays': consecutiveDays,
  };

  factory DailyEmotionCard.fromMap(Map<String, dynamic> map) {
    return DailyEmotionCard(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      emotion: EmotionType.values.byName(map['emotion'] ?? 'joy'),
      userMessage: map['userMessage'] ?? '',
      generatedImage: map['generatedImage'],
      generatedName: map['generatedName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      consecutiveDays: map['consecutiveDays'] ?? 1,
    );
  }

  DailyEmotionCard copyWith({
    String? id,
    String? userId,
    EmotionType? emotion,
    String? userMessage,
    String? generatedImage,
    String? generatedName,
    DateTime? createdAt,
    int? consecutiveDays,
  }) {
    return DailyEmotionCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emotion: emotion ?? this.emotion,
      userMessage: userMessage ?? this.userMessage,
      generatedImage: generatedImage ?? this.generatedImage,
      generatedName: generatedName ?? this.generatedName,
      createdAt: createdAt ?? this.createdAt,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
    );
  }
}

class EmotionStats {
  final int totalDays;
  final int currentStreak;
  final int joyDays;
  final int angerDays;
  final int sadnessDays;
  final DateTime? lastEmotionDate;

  EmotionStats({
    required this.totalDays,
    required this.currentStreak,
    required this.joyDays,
    required this.angerDays,
    required this.sadnessDays,
    this.lastEmotionDate,
  });

  double get joyPercent => totalDays == 0 ? 0 : (joyDays / totalDays * 100);
  double get angerPercent => totalDays == 0 ? 0 : (angerDays / totalDays * 100);
  double get sadnessPercent => totalDays == 0 ? 0 : (sadnessDays / totalDays * 100);

  Map<String, dynamic> toMap() => {
    'totalDays': totalDays,
    'currentStreak': currentStreak,
    'joyDays': joyDays,
    'angerDays': angerDays,
    'sadnessDays': sadnessDays,
    'lastEmotionDate': lastEmotionDate != null ? Timestamp.fromDate(lastEmotionDate!) : null,
  };

  factory EmotionStats.fromMap(Map<String, dynamic> map) {
    return EmotionStats(
      totalDays: map['totalDays'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      joyDays: map['joyDays'] ?? 0,
      angerDays: map['angerDays'] ?? 0,
      sadnessDays: map['sadnessDays'] ?? 0,
      lastEmotionDate: (map['lastEmotionDate'] as Timestamp?)?.toDate(),
    );
  }
}
