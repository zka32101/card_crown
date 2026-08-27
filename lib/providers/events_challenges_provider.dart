import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/event_challenge.dart';
import 'auth_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Providers - Events & Challenges
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// すべてのアクティブなイベントを取得
final activeEventsProvider = FutureProvider<List<GameEvent>>((ref) async {
  try {
    final now = DateTime.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endDate')
        .get();

    return querySnapshot.docs
        .map((doc) => GameEvent.fromMap(doc.data(), id: doc.id))
        .toList();
  } catch (e) {
    debugPrint('Error loading active events: $e');
    return [];
  }
});

/// すべてのイベント（アクティブ + 予定 + 終了）を取得
final allEventsProvider = FutureProvider<List<GameEvent>>((ref) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('startDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => GameEvent.fromMap(doc.data(), id: doc.id))
        .toList();
  } catch (e) {
    debugPrint('Error loading all events: $e');
    return [];
  }
});

/// 特定のイベント詳細を取得
final eventDetailProvider = FutureProvider.family<GameEvent?, String>((ref, eventId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return GameEvent.fromMap(doc.data() ?? {}, id: doc.id);
  } catch (e) {
    debugPrint('Error loading event detail: $e');
    return null;
  }
});

/// イベントのすべてのチャレンジを取得
final eventChallengesProvider = FutureProvider.family<List<Challenge>, String>((ref, eventId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('challenges')
        .orderBy('difficulty')
        .get();

    return querySnapshot.docs
        .map((doc) => Challenge.fromMap(doc.data(), id: doc.id))
        .toList();
  } catch (e) {
    debugPrint('Error loading challenges for event: $e');
    return [];
  }
});

/// ユーザーのイベント進捗を取得
final userEventProgressProvider = FutureProvider.family<List<UserChallengeProgress>, String>((ref, eventId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventProgress')
        .where('eventId', isEqualTo: eventId)
        .get();

    return querySnapshot.docs
        .map((doc) => UserChallengeProgress.fromMap(doc.data()))
        .toList();
  } catch (e) {
    debugPrint('Error loading user event progress: $e');
    return [];
  }
});

/// 特定のチャレンジのユーザー進捗を取得
final userChallengeProgressProvider = FutureProvider.family<UserChallengeProgress?, (String, String)>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return null;
  }

  final (eventId, challengeId) = params;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventProgress')
        .doc('${eventId}_$challengeId')
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserChallengeProgress.fromMap(doc.data() ?? {});
  } catch (e) {
    debugPrint('Error loading challenge progress: $e');
    return null;
  }
});

/// ユーザーが参加しているアクティブなイベント
final userActiveEventsProvider = FutureProvider<List<GameEvent>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  try {
    // ユーザーの進捗があるイベントをすべて取得
    final progressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventProgress')
        .get();

    final eventIds = <String>{};
    for (final doc in progressSnapshot.docs) {
      final eventId = doc['eventId'] as String?;
      if (eventId != null) {
        eventIds.add(eventId);
      }
    }

    if (eventIds.isEmpty) {
      return [];
    }

    // イベント詳細を取得
    final now = DateTime.now();
    final events = <GameEvent>[];

    for (final eventId in eventIds) {
      try {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

        if (eventDoc.exists) {
          final event = GameEvent.fromMap(eventDoc.data() ?? {}, id: eventDoc.id);
          // 進行中のみを返す
          if (event.isActive) {
            events.add(event);
          }
        }
      } catch (e) {
        debugPrint('Error loading event $eventId: $e');
      }
    }

    return events;
  } catch (e) {
    debugPrint('Error loading user active events: $e');
    return [];
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Helper Functions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// チャレンジの進捗を更新
Future<void> progressChallenge(
  WidgetRef ref, {
  required String eventId,
  required String challengeId,
  required int progressAmount,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('eventProgress')
        .doc('${eventId}_$challengeId')
        .update({
      'progress': FieldValue.increment(progressAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // プロバイダをリフレッシュ
    ref.invalidate(userEventProgressProvider(eventId));
    ref.invalidate(userChallengeProgressProvider((eventId, challengeId)));
  } catch (e) {
    debugPrint('Error progressing challenge: $e');
    rethrow;
  }
}

/// チャレンジのリワードを受け取る
Future<({int gemReward, int coinReward})> claimChallengeReward(
  WidgetRef ref, {
  required String eventId,
  required String challengeId,
}) async {
  try {
    // Cloud Functionを呼び出す（本来はこちら）
    // final result = await functions.call('claimChallengeReward', {
    //   'eventId': eventId,
    //   'challengeId': challengeId,
    // });

    // ここではシミュレーション（実際はCloud Functionを呼び出すべき）
    final gemsReward = 50;
    final coinsReward = 500;

    // プロバイダをリフレッシュ
    ref.invalidate(userChallengeProgressProvider((eventId, challengeId)));
    ref.invalidate(userEventProgressProvider(eventId));

    return (gemReward: gemsReward, coinReward: coinsReward);
  } catch (e) {
    debugPrint('Error claiming reward: $e');
    rethrow;
  }
}
