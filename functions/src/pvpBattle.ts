import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PvPバトル判定（サーバー権威）
// lib/services/battle_engine.dart のロジックをそのまま移植。
// クライアント側の計算結果を信用せず、サーバー側で同じアルゴリズムを再計算することで
// ダメージ・勝敗の改ざんを防ぐ。レーティング更新もここで行う。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

interface CardInput {
  cardId: string;
  attribute: string;
  attackPower: number;
  defensePower: number;
  speed: number;
}

interface BattleLogEntry {
  turn: number;
  attackerCardId: string;
  defenderCardId: string;
  damage: number;
  // このターンの後の、対戦全体を通した「攻め手側デッキ／受け手側デッキ」のHP
  // （現在の打ち手がどちらかに関わらず、常に元のattackerDeck/defenderDeckを指す。
  //  lib/services/battle_engine.dart の BattleLog.attackerHp/defenderHp と同じ意味）
  attackerHp: number;
  defenderHp: number;
  multiplier: number;
}

function getAttributeMultiplier(attackerAttribute: string, defenderAttribute: string): number {
  // 喜 → 怒 / 怒 → 哀 / 哀 → 喜 の三すくみ
  if (attackerAttribute === defenderAttribute) return 1.0;
  if (attackerAttribute === "joy" && defenderAttribute === "anger") return 1.5;
  if (attackerAttribute === "anger" && defenderAttribute === "sadness") return 1.5;
  if (attackerAttribute === "sadness" && defenderAttribute === "joy") return 1.5;
  return 0.67;
}

// 「属性の国」移住ボーナス：移住先属性のカードで攻撃した際に加算される倍率
// lib/services/battle_engine.dart の migrationBonus と同じ値
const MIGRATION_BONUS = 0.15;

function effectiveMultiplier(
  attackerAttribute: string,
  defenderAttribute: string,
  boosted: boolean
): number {
  const base = getAttributeMultiplier(attackerAttribute, defenderAttribute);
  return boosted ? base + MIGRATION_BONUS : base;
}

function damageFromMultiplier(attacker: CardInput, defender: CardInput, multiplier: number): number {
  const raw = attacker.attackPower - defender.defensePower;
  const dmg = Math.floor(raw * multiplier);
  return dmg < 1 ? 1 : dmg;
}

function simulateBattle(
  attackerDeck: CardInput[],
  defenderDeck: CardInput[],
  migratedAttribute?: string
) {
  const initialHp = 30;
  let attackerHp = initialHp;
  let defenderHp = initialHp;
  const logs: BattleLogEntry[] = [];
  const len = Math.min(attackerDeck.length, defenderDeck.length);
  let turn = 1;

  for (let i = 0; i < len; i++) {
    const attCard = attackerDeck[i];
    const defCard = defenderDeck[i];
    const attackerGoesFirst = attCard.speed >= defCard.speed;
    // attackerDeck側（元の攻撃側プレイヤー）のカードが打つ攻撃だけが移住ボーナス対象
    const attCardBoosted = attCard.attribute === migratedAttribute;

    if (attackerGoesFirst) {
      const m1 = effectiveMultiplier(attCard.attribute, defCard.attribute, attCardBoosted);
      const dmg1 = damageFromMultiplier(attCard, defCard, m1);
      defenderHp -= dmg1;
      logs.push({
        turn: turn++, attackerCardId: attCard.cardId, defenderCardId: defCard.cardId,
        damage: dmg1, attackerHp, defenderHp, multiplier: m1,
      });
      if (defenderHp <= 0) break;

      const m2 = effectiveMultiplier(defCard.attribute, attCard.attribute, false);
      const dmg2 = damageFromMultiplier(defCard, attCard, m2);
      attackerHp -= dmg2;
      logs.push({
        turn: turn++, attackerCardId: defCard.cardId, defenderCardId: attCard.cardId,
        damage: dmg2, attackerHp, defenderHp, multiplier: m2,
      });
      if (attackerHp <= 0) break;
    } else {
      const m1 = effectiveMultiplier(defCard.attribute, attCard.attribute, false);
      const dmg1 = damageFromMultiplier(defCard, attCard, m1);
      attackerHp -= dmg1;
      logs.push({
        turn: turn++, attackerCardId: defCard.cardId, defenderCardId: attCard.cardId,
        damage: dmg1, attackerHp, defenderHp, multiplier: m1,
      });
      if (attackerHp <= 0) break;

      const m2 = effectiveMultiplier(attCard.attribute, defCard.attribute, attCardBoosted);
      const dmg2 = damageFromMultiplier(attCard, defCard, m2);
      defenderHp -= dmg2;
      logs.push({
        turn: turn++, attackerCardId: attCard.cardId, defenderCardId: defCard.cardId,
        damage: dmg2, attackerHp, defenderHp, multiplier: m2,
      });
      if (defenderHp <= 0) break;
    }
  }

  const attackerWon = attackerHp >= defenderHp;
  return {
    attackerWon,
    finalAttackerHp: Math.max(0, Math.min(initialHp, attackerHp)),
    finalDefenderHp: Math.max(0, Math.min(initialHp, defenderHp)),
    logs,
  };
}

interface PvpBattleRequest {
  attackerDeck: CardInput[];
  defenderDeckSnapshot: CardInput[];
  defenderUid?: string;
  migratedAttribute?: string;
}

export const pvpBattle = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: PvpBattleRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }

    const attackerDeck = data.attackerDeck ?? [];
    const defenderDeckSnapshot = data.defenderDeckSnapshot ?? [];
    if (attackerDeck.length === 0 || defenderDeckSnapshot.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "デッキが不正です");
    }

    const result = simulateBattle(attackerDeck, defenderDeckSnapshot, data.migratedAttribute);

    // レーティング更新（簡易固定幅）
    // TODO: 相手レーティング差を考慮したELO式に拡張できる
    const userId = context.auth.uid;
    const ratingDelta = result.attackerWon ? 15 : -10;
    const ratingRef = admin.firestore()
      .collection("users").doc(userId)
      .collection("rating").doc("current");

    const newRating = await admin.firestore().runTransaction(async (tx) => {
      const doc = await tx.get(ratingRef);
      const before = doc.data() ?? {};
      const currentRating: number = before.rating ?? 1000;
      const wins: number = before.wins ?? 0;
      const losses: number = before.losses ?? 0;
      const updatedRating = Math.max(0, currentRating + ratingDelta);
      tx.set(ratingRef, {
        rating: updatedRating,
        wins: wins + (result.attackerWon ? 1 : 0),
        losses: losses + (result.attackerWon ? 0 : 1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return updatedRating;
    });

    return {...result, newRating, ratingDelta};
  });
