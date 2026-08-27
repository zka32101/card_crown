import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/season.dart';
import 'auth_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Providers - Seasons System
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 現在のアクティブなシーズンを取得
final currentSeasonProvider = FutureProvider<Season?>((ref) async {
  try {
    final now = DateTime.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('seasons')
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return Season.fromMap(doc.data(), id: doc.id);
  } catch (e) {
    debugPrint('Error loading current season: $e');
    return null;
  }
});

/// 次のシーズンを取得
final nextSeasonProvider = FutureProvider<Season?>((ref) async {
  try {
    final now = DateTime.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('seasons')
        .where('startDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startDate')
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return Season.fromMap(doc.data(), id: doc.id);
  } catch (e) {
    debugPrint('Error loading next season: $e');
    return null;
  }
});

/// すべてのシーズンを取得（ページング対応）
final allSeasonsProvider = FutureProvider<List<Season>>((ref) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('seasons')
        .orderBy('startDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Season.fromMap(doc.data(), id: doc.id))
        .toList();
  } catch (e) {
    debugPrint('Error loading all seasons: $e');
    return [];
  }
});

/// 特定シーズンの詳細情報を取得
final seasonDetailProvider = FutureProvider.family<Season?, String>((ref, seasonId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('seasons')
        .doc(seasonId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return Season.fromMap(doc.data() ?? {}, id: doc.id);
  } catch (e) {
    debugPrint('Error loading season detail: $e');
    return null;
  }
});

/// ユーザーの現在のシーズン進捗を取得
final userCurrentSeasonProgressProvider = FutureProvider<UserSeasonProgress?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final currentSeason = ref.watch(currentSeasonProvider);

  if (userId == null || currentSeason.isLoading || currentSeason.value == null) {
    return null;
  }

  try {
    final seasonId = currentSeason.value!.id;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seasonProgress')
        .doc(seasonId)
        .get();

    if (!doc.exists) {
      // シーズン進捗が存在しない場合は新規作成
      final newProgress = UserSeasonProgress(
        seasonId: seasonId,
        userId: userId,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return newProgress;
    }

    return UserSeasonProgress.fromMap(doc.data() ?? {});
  } catch (e) {
    debugPrint('Error loading user season progress: $e');
    return null;
  }
});

/// ユーザーの指定シーズン進捗を取得
final userSeasonProgressProvider = FutureProvider.family<UserSeasonProgress?, String>((ref, seasonId) async {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return null;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seasonProgress')
        .doc(seasonId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserSeasonProgress.fromMap(doc.data() ?? {});
  } catch (e) {
    debugPrint('Error loading user season progress: $e');
    return null;
  }
});

/// シーズンのランクリワード一覧を取得
final seasonRewardsProvider = FutureProvider.family<List<SeasonRankReward>, String>((ref, seasonId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('seasons')
        .doc(seasonId)
        .collection('rewards')
        .orderBy('rankTier')
        .get();

    return querySnapshot.docs
        .map((doc) => SeasonRankReward.fromMap(doc.data(), id: doc.id))
        .toList();
  } catch (e) {
    debugPrint('Error loading season rewards: $e');
    return [];
  }
});

/// シーズンランキング（トップ100）を取得
final seasonLeaderboardProvider = FutureProvider.family<List<UserSeasonProgress>, String>((ref, seasonId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final allProgress = <UserSeasonProgress>[];
    for (final userDoc in querySnapshot.docs) {
      try {
        final progressDoc = await userDoc.reference
            .collection('seasonProgress')
            .doc(seasonId)
            .get();

        if (progressDoc.exists) {
          allProgress.add(UserSeasonProgress.fromMap(progressDoc.data() ?? {}));
        }
      } catch (e) {
        debugPrint('Error loading user progress: $e');
      }
    }

    // ランクとポイントでソート（高い順）
    allProgress.sort((a, b) {
      if (a.currentRank != b.currentRank) {
        return b.currentRank.compareTo(a.currentRank);
      }
      if (a.currentRankPoints != b.currentRankPoints) {
        return b.currentRankPoints.compareTo(a.currentRankPoints);
      }
      return b.totalSeasonPoints.compareTo(a.totalSeasonPoints);
    });

    return allProgress.take(100).toList();
  } catch (e) {
    debugPrint('Error loading season leaderboard: $e');
    return [];
  }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Functions - Season Progress Updates
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// シーズン進捗を更新（バトル勝利時）
Future<bool> updateSeasonProgressOnWin(
  Ref ref, {
  required String userId,
  required String seasonId,
  required int pointsGained,
}) async {
  try {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seasonProgress')
        .doc(seasonId);

    final doc = await userDocRef.get();
    UserSeasonProgress progress;

    if (!doc.exists) {
      progress = UserSeasonProgress(
        seasonId: seasonId,
        userId: userId,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      progress = UserSeasonProgress.fromMap(doc.data() ?? {});
    }

    // 勝利数とポイントを更新
    var newRankPoints = progress.currentRankPoints + pointsGained;
    var newRank = progress.currentRank;
    var newHighestRank = progress.highestRank;

    // ランクアップ判定（100ポイントで次のランクへ）
    while (newRankPoints >= 100) {
      newRankPoints -= 100;
      newRank += 1;
      if (newRank > newHighestRank) {
        newHighestRank = newRank;
      }
    }

    // 更新データ
    final updatedProgress = progress.copyWith(
      battlesWon: progress.battlesWon + 1,
      battlesPlayed: progress.battlesPlayed + 1,
      currentRank: newRank,
      currentRankPoints: newRankPoints,
      totalSeasonPoints: progress.totalSeasonPoints + pointsGained,
      highestRank: newHighestRank,
      updatedAt: DateTime.now(),
    );

    await userDocRef.set(updatedProgress.toMap(), SetOptions(merge: true));
    return true;
  } catch (e) {
    debugPrint('Error updating season progress on win: $e');
    return false;
  }
}

/// シーズン進捗を更新（バトル敗北時）
Future<bool> updateSeasonProgressOnLoss(
  Ref ref, {
  required String userId,
  required String seasonId,
}) async {
  try {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seasonProgress')
        .doc(seasonId);

    final doc = await userDocRef.get();
    UserSeasonProgress progress;

    if (!doc.exists) {
      progress = UserSeasonProgress(
        seasonId: seasonId,
        userId: userId,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      progress = UserSeasonProgress.fromMap(doc.data() ?? {});
    }

    // 敗北数をカウント
    final updatedProgress = progress.copyWith(
      battlesPlayed: progress.battlesPlayed + 1,
      updatedAt: DateTime.now(),
    );

    await userDocRef.set(updatedProgress.toMap(), SetOptions(merge: true));
    return true;
  } catch (e) {
    debugPrint('Error updating season progress on loss: $e');
    return false;
  }
}

/// リワードを請求（ランク到達時）
Future<bool> claimSeasonReward(
  Ref ref, {
  required String userId,
  required String seasonId,
  required String rewardId,
}) async {
  try {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seasonProgress')
        .doc(seasonId);

    final doc = await userDocRef.get();
    if (!doc.exists) {
      return false;
    }

    final progress = UserSeasonProgress.fromMap(doc.data() ?? {});

    // 既に請求済みの場合はスキップ
    if (progress.unlockedRewards.contains(rewardId)) {
      return false;
    }

    // リワードを追加
    final updatedRewards = [...progress.unlockedRewards, rewardId];
    final updatedProgress = progress.copyWith(
      unlockedRewards: updatedRewards,
      updatedAt: DateTime.now(),
    );

    await userDocRef.set(updatedProgress.toMap(), SetOptions(merge: true));
    return true;
  } catch (e) {
    debugPrint('Error claiming season reward: $e');
    return false;
  }
}
