import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/leaderboard.dart';

// 現在の週情報
final currentWeekProvider = Provider<(int, int)>((ref) {
  final now = DateTime.now();
  final firstDayOfYear = DateTime(now.year, 1, 1);
  final daysFromFirstDay = now.difference(firstDayOfYear).inDays;
  final weekNumber = (daysFromFirstDay / 7).ceil();
  return (weekNumber, now.year);
});

// 現在の月情報
final currentMonthProvider = Provider<(int, int)>((ref) {
  final now = DateTime.now();
  return (now.month, now.year);
});

// オールタイムランキング（ELO順）
final allTimeLeaderboardProvider = StateProvider<List<LeaderboardEntry>>((ref) {
  // ダミーデータ（本実装では Firestore から取得）
  return _generateDummyLeaderboard();
});

// 週間ランキング
final weeklyLeaderboardProvider = StateProvider<WeeklyLeaderboard?>((ref) {
  final (week, year) = ref.watch(currentWeekProvider);
  // ダミーデータ（本実装では Firestore から取得）
  return WeeklyLeaderboard(
    weekNumber: week,
    year: year,
    entries: _generateDummyLeaderboard(),
    weekStart: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    weekEnd: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
  );
});

// 月間ランキング
final monthlyLeaderboardProvider = StateProvider<MonthlyLeaderboard?>((ref) {
  final (month, year) = ref.watch(currentMonthProvider);
  // ダミーデータ（本実装では Firestore から取得）
  return MonthlyLeaderboard(
    month: month,
    year: year,
    entries: _generateDummyLeaderboard(),
    updatedAt: DateTime.now(),
  );
});

// 属性別ランキング（喜）
final joyLeaderboardProvider = StateProvider<AttributeLeaderboard?>((ref) {
  return AttributeLeaderboard(
    attribute: 'joy',
    entries: _generateDummyLeaderboard().take(10).toList(),
    updatedAt: DateTime.now(),
  );
});

// 属性別ランキング（怒）
final angerLeaderboardProvider = StateProvider<AttributeLeaderboard?>((ref) {
  return AttributeLeaderboard(
    attribute: 'anger',
    entries: _generateDummyLeaderboard().take(10).toList(),
    updatedAt: DateTime.now(),
  );
});

// 属性別ランキング（哀）
final sadnessLeaderboardProvider = StateProvider<AttributeLeaderboard?>((ref) {
  return AttributeLeaderboard(
    attribute: 'sadness',
    entries: _generateDummyLeaderboard().take(10).toList(),
    updatedAt: DateTime.now(),
  );
});

List<LeaderboardEntry> _generateDummyLeaderboard() {
  final names = ['KamiCard_99', 'EmotionMaster', 'SadnessKing', 'JoyHunter', 'AngerBurst'];
  final tiers = ['diamond', 'platinum', 'gold', 'gold', 'silver'];
  final ratings = [2450, 1920, 1750, 1620, 1400];

  return List.generate(5, (i) => LeaderboardEntry(
    rank: i + 1,
    userId: 'user_${i + 1}',
    userName: names[i],
    tier: tiers[i],
    rating: ratings[i],
    wins: 100 - (i * 20),
    losses: 30 + (i * 10),
    updatedAt: DateTime.now(),
  ));
}
