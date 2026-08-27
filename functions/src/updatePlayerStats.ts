import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// プレイヤー統計の更新（サーバー権威）
// PvP バトル勝敗時に呼び出され、プレイヤーのランキングデータを更新する。
// 更新内容：総バトル数、勝敗記録、現在のレーティング、連勝記録など
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

interface UpdatePlayerStatsRequest {
  opponentUid: string;
  isWin: boolean;
  ratingChange: number;
  newRating: number;
}

interface PlayerStats {
  totalBattles: number;
  totalWins: number;
  currentRating: number;
  winStreak: number;
  maxWinStreak: number;
  lossStreak: number;
  maxLossStreak: number;
  lastBattleAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

export const updatePlayerStats = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: UpdatePlayerStatsRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }

    const playerId = context.auth.uid;
    const {opponentUid, isWin, ratingChange, newRating} = data;

    if (!opponentUid || ratingChange === undefined || newRating === undefined) {
      throw new functions.https.HttpsError("invalid-argument", "リクエストが不正です");
    }

    const db = admin.firestore();
    const playerStatsRef = db.collection("users").doc(playerId).collection("stats").doc("overall");

    try {
      await db.runTransaction(async (tx) => {
        const statsDoc = await tx.get(playerStatsRef);
        const stats = statsDoc.data() as PlayerStats | undefined;

        // 初回のプレイヤーの場合はデフォルト値で初期化
        const currentStats: PlayerStats = stats || {
          totalBattles: 0,
          totalWins: 0,
          currentRating: 1200,
          winStreak: 0,
          maxWinStreak: 0,
          lossStreak: 0,
          maxLossStreak: 0,
          lastBattleAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        };

        // 統計を更新
        currentStats.totalBattles += 1;
        currentStats.currentRating = newRating;
        currentStats.lastBattleAt = admin.firestore.Timestamp.now();
        currentStats.updatedAt = admin.firestore.Timestamp.now();

        if (isWin) {
          currentStats.totalWins += 1;
          currentStats.winStreak += 1;
          currentStats.lossStreak = 0;
        } else {
          currentStats.lossStreak += 1;
          currentStats.winStreak = 0;
        }

        // 最大連勝/連敗記録を更新
        if (currentStats.winStreak > currentStats.maxWinStreak) {
          currentStats.maxWinStreak = currentStats.winStreak;
        }
        if (currentStats.lossStreak > currentStats.maxLossStreak) {
          currentStats.maxLossStreak = currentStats.lossStreak;
        }

        tx.set(playerStatsRef, currentStats, {merge: true});
      });

      return {success: true, stats: {rating: newRating, totalWins: newRating}};
    } catch (error) {
      console.error(`Failed to update player stats for ${playerId}:`, error);
      throw new functions.https.HttpsError(
        "internal",
        "プレイヤー統計の更新に失敗しました"
      );
    }
  });
