import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_emotion_card.dart';

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

// 本日の感情カードを取得
final todayEmotionCardProvider = FutureProvider<DailyEmotionCard?>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return null;

  final firestore = ref.watch(firestoreProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

  final query = await firestore
      .collection('users')
      .doc(userId)
      .collection('daily_emotions')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .limit(1)
      .get();

  if (query.docs.isEmpty) return null;
  return DailyEmotionCard.fromMap(query.docs.first.data());
});

// 感情履歴を取得（直近30日）
final emotionHistoryProvider = FutureProvider<List<DailyEmotionCard>>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return [];

  final firestore = ref.watch(firestoreProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

  final query = await firestore
      .collection('users')
      .doc(userId)
      .collection('daily_emotions')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('createdAt', descending: true)
      .get();

  return query.docs.map((doc) => DailyEmotionCard.fromMap(doc.data())).toList();
});

// 統計情報を取得
final emotionStatsProvider = FutureProvider<EmotionStats>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return EmotionStats(
      totalDays: 0,
      currentStreak: 0,
      joyDays: 0,
      angerDays: 0,
      sadnessDays: 0,
    );
  }

  final firestore = ref.watch(firestoreProvider);
  final statsDoc = await firestore.collection('users').doc(userId).collection('daily_emotion_stats').doc('stats').get();

  if (!statsDoc.exists) {
    return EmotionStats(
      totalDays: 0,
      currentStreak: 0,
      joyDays: 0,
      angerDays: 0,
      sadnessDays: 0,
    );
  }

  return EmotionStats.fromMap(statsDoc.data() ?? {});
});

// 感情カード作成（Riverpod StateNotifier の代わりに、非同期処理）
final createDailyEmotionProvider =
    FutureProvider.family<DailyEmotionCard, (EmotionType, String)>((ref, params) async {
  final (emotion, message) = params;
  final userId = await ref.watch(currentUserIdProvider.future);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  const uuid = Uuid();
  final cardId = uuid.v4();
  final now = DateTime.now();

  // 1. 新規カードオブジェクト作成
  final card = DailyEmotionCard(
    id: cardId,
    userId: userId,
    emotion: emotion,
    userMessage: message,
    createdAt: now,
    consecutiveDays: 1,
  );

  // 2. Cloud Function を呼び出す（将来的に）
  // generateCardName + generateCardImage
  // TODO: Firebase Functions との連携

  // 3. Firestore に保存
  final firestore = ref.watch(firestoreProvider);
  await firestore
      .collection('users')
      .doc(userId)
      .collection('daily_emotions')
      .doc(cardId)
      .set(card.toMap());

  // 4. 統計情報を更新
  await _updateEmotionStreak(firestore, userId, emotion);

  // 統計をリフレッシュ
  ref.invalidate(emotionStatsProvider);
  ref.invalidate(todayEmotionCardProvider);
  ref.invalidate(emotionHistoryProvider);

  return card;
});

// ストリーク更新（内部ヘルパー）
Future<void> _updateEmotionStreak(
    FirebaseFirestore firestore, String userId, EmotionType emotion) async {
  final statsRef = firestore
      .collection('users')
      .doc(userId)
      .collection('daily_emotion_stats')
      .doc('stats');

  final statsDoc = await statsRef.get();
  final currentStats = statsDoc.exists
      ? EmotionStats.fromMap(statsDoc.data() ?? {})
      : EmotionStats(
          totalDays: 0,
          currentStreak: 0,
          joyDays: 0,
          angerDays: 0,
          sadnessDays: 0,
        );

  // 昨日の感情カードがあるか確認
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
  final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

  final yesterdayQuery = await firestore
      .collection('users')
      .doc(userId)
      .collection('daily_emotions')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
      .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYesterday))
      .limit(1)
      .get();

  final newStreak = yesterdayQuery.docs.isNotEmpty ? currentStats.currentStreak + 1 : 1;

  // カウンター更新
  final newJoyDays = currentStats.joyDays + (emotion == EmotionType.joy ? 1 : 0);
  final newAngerDays = currentStats.angerDays + (emotion == EmotionType.anger ? 1 : 0);
  final newSadnessDays = currentStats.sadnessDays + (emotion == EmotionType.sadness ? 1 : 0);

  final updatedStats = currentStats.copyWith(
    totalDays: currentStats.totalDays + 1,
    currentStreak: newStreak,
    joyDays: newJoyDays,
    angerDays: newAngerDays,
    sadnessDays: newSadnessDays,
    lastEmotionDate: DateTime.now(),
  );

  await statsRef.set(updatedStats.toMap(), SetOptions(merge: true));
}

// EmotionStats の copyWith メソッドの拡張
extension EmotionStatsCopyWith on EmotionStats {
  EmotionStats copyWith({
    int? totalDays,
    int? currentStreak,
    int? joyDays,
    int? angerDays,
    int? sadnessDays,
    DateTime? lastEmotionDate,
  }) {
    return EmotionStats(
      totalDays: totalDays ?? this.totalDays,
      currentStreak: currentStreak ?? this.currentStreak,
      joyDays: joyDays ?? this.joyDays,
      angerDays: angerDays ?? this.angerDays,
      sadnessDays: sadnessDays ?? this.sadnessDays,
      lastEmotionDate: lastEmotionDate ?? this.lastEmotionDate,
    );
  }
}
