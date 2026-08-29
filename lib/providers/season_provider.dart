import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/season.dart';
import '../services/functions_service.dart';
import 'auth_provider.dart';
import 'game_state_provider.dart';

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
// 勝利/敗北時のシーズン進捗更新（ランク・ポイント・battlesWon/Played）は、
// PvPバトルを実行するpvpBattle Cloud Function内でサーバー権威で行われる。
// lib/providers/game_state_provider.dart の myPlayerRankProvider（レーティング）と
// 同じ方針で、ここには「勝利/敗北をローカルで反映する」ような更新手段を意図的に
// 置かない —— かつてはここに直接Firestoreへ書き込む関数があったが、どこからも
// 呼ばれておらず、しかもクライアントの自己申告をそのまま信用する実装だったため、
// 実際の対戦結果と無関係にランク/ポイントを詐取できてしまう欠陥だった
// （firestore.rulesでもseasonProgressへのクライアント書き込みは禁止済み）。

/// シーズンリワードを請求（ランク到達時・サーバー権威）。
/// ランク到達判定・請求済みチェック・ジェム/コイン付与はclaimSeasonReward
/// Cloud Function側でアトミックに行う。成功時はローカルウォレットにも反映してnullを返し、
/// 失敗時（ランク不足・請求済みなど）はサーバー側のエラーメッセージを返す。
Future<String?> claimSeasonReward(
  WidgetRef ref, {
  required String seasonId,
  required String rewardId,
}) async {
  try {
    final result = await FunctionsService.claimSeasonReward(
      seasonId: seasonId,
      rewardId: rewardId,
    );
    final gemsGranted = (result['gemsGranted'] as int?) ?? 0;
    final coinsGranted = (result['coinsGranted'] as int?) ?? 0;
    if (gemsGranted > 0 || coinsGranted > 0) {
      final wallet = ref.read(walletProvider);
      ref.read(walletProvider.notifier).state = wallet.copyWith(
        gemBalance: wallet.gemBalance + gemsGranted,
        coinBalance: wallet.coinBalance + coinsGranted,
      );
    }
    return null;
  } on FirebaseFunctionsException catch (e) {
    return e.message ?? 'unknown error';
  } catch (_) {
    return 'unknown error';
  }
}
