import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// シーズンリワード請求（サーバー権威）
// users/{uid}/seasonProgress/{seasonId} はpvpBattle Cloud Functionのみが更新でき、
// firestore.rulesでクライアントからの直接書き込みを禁止している。そのため
// unlockedRewardsへの追加や、リワードのジェム/コイン付与も必ずこのCloud Function
// 経由で行う（rentCard.ts/pvpBattle.tsと同じ「通貨が絡む更新はサーバーのみ」方針）。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

interface ClaimSeasonRewardRequest {
  seasonId: string;
  rewardId: string;
}

// ウォレット未作成（初回アクセス前）の場合のデフォルト残高。
// lib/providers/game_state_provider.dart の WalletState() のデフォルトと同じ値。
const DEFAULT_COIN_BALANCE = 100;
const DEFAULT_GEM_BALANCE = 0;

export const claimSeasonReward = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: ClaimSeasonRewardRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }
    const userId = context.auth.uid;
    const {seasonId, rewardId} = data;

    if (!seasonId || !rewardId) {
      throw new functions.https.HttpsError("invalid-argument", "リクエストが不正です");
    }

    const db = admin.firestore();
    const rewardRef = db.collection("seasons").doc(seasonId).collection("rewards").doc(rewardId);
    const progressRef = db.collection("users").doc(userId).collection("seasonProgress").doc(seasonId);
    const walletRef = db.collection("users").doc(userId).collection("wallet").doc("balance");

    try {
      return await db.runTransaction(async (tx) => {
        // ── 読み取りは書き込みより先に行う（Firestoreトランザクションの制約） ──
        const rewardDoc = await tx.get(rewardRef);
        if (!rewardDoc.exists) {
          throw new functions.https.HttpsError("not-found", "リワードが見つかりません");
        }
        const reward = rewardDoc.data()!;
        const rankTier: number = reward.rankTier ?? 1;
        const gemsReward: number = reward.gemsReward ?? 0;
        const coinsReward: number = reward.coinsReward ?? 0;

        const progressDoc = await tx.get(progressRef);
        if (!progressDoc.exists) {
          throw new functions.https.HttpsError("failed-precondition", "シーズン進捗が見つかりません");
        }
        const progress = progressDoc.data()!;
        const currentRank: number = progress.currentRank ?? 1;
        const unlockedRewards: string[] = progress.unlockedRewards ?? [];

        // season_screen.dart の isUnlocked 判定（currentRank基準）と揃える
        if (currentRank < rankTier) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "このリワードを受け取るにはランクが足りません"
          );
        }
        if (unlockedRewards.includes(rewardId)) {
          throw new functions.https.HttpsError("failed-precondition", "このリワードは既に受け取り済みです");
        }

        const walletDoc = await tx.get(walletRef);
        const walletData = walletDoc.data() ?? {};
        const coinBalance: number = walletData.coinBalance ?? DEFAULT_COIN_BALANCE;
        const gemBalance: number = walletData.gemBalance ?? DEFAULT_GEM_BALANCE;

        // ── ここから書き込み ──
        tx.set(progressRef, {
          unlockedRewards: [...unlockedRewards, rewardId],
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        tx.set(walletRef, {
          coinBalance: coinBalance + coinsReward,
          gemBalance: gemBalance + gemsReward,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        return {success: true, gemsGranted: gemsReward, coinsGranted: coinsReward};
      });
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error(`Failed to claim season reward for ${userId}:`, error);
      throw new functions.https.HttpsError("internal", "リワード受取に失敗しました");
    }
  });
