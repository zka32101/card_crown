import '../models/battle_models.dart';
import '../models/user_card.dart';

// 決定論的バトルシミュレーション（乱数なし）
class BattleEngine {
  static const int initialHp = 30;

  static BattleResult simulate(
    List<PlayCard> attackerDeck,
    List<PlayCard> defenderDeck,
  ) {
    int attackerHp = initialHp;
    int defenderHp = initialHp;
    final List<BattleLog> logs = [];
    int turn = 1;

    // カードをスピード降順にソートして先攻後攻を決める
    for (int i = 0; i < attackerDeck.length && i < defenderDeck.length; i++) {
      final attCard = attackerDeck[i];
      final defCard = defenderDeck[i];

      // 先攻判定：スピードが高い方が先攻
      final bool attackerGoesFirst = attCard.speed >= defCard.speed;

      if (attackerGoesFirst) {
        final m1 = getAttributeMultiplier(attCard.attribute, defCard.attribute);
        final dmg1 = _calcDamage(attCard, defCard);
        defenderHp -= dmg1;
        logs.add(BattleLog(
          turn: turn++,
          action: '${attCard.nameJp} が ${defCard.nameJp} に攻撃',
          damage: dmg1,
          attackerHp: attackerHp,
          defenderHp: defenderHp,
          attackingCard: attCard,
          defendingCard: defCard,
          multiplier: m1,
        ));

        if (defenderHp <= 0) break;

        final m2 = getAttributeMultiplier(defCard.attribute, attCard.attribute);
        final dmg2 = _calcDamage(defCard, attCard);
        attackerHp -= dmg2;
        logs.add(BattleLog(
          turn: turn++,
          action: '${defCard.nameJp} が ${attCard.nameJp} に反撃',
          damage: dmg2,
          attackerHp: attackerHp,
          defenderHp: defenderHp,
          attackingCard: defCard,
          defendingCard: attCard,
          multiplier: m2,
        ));

        if (attackerHp <= 0) break;
      } else {
        final m1 = getAttributeMultiplier(defCard.attribute, attCard.attribute);
        final dmg1 = _calcDamage(defCard, attCard);
        attackerHp -= dmg1;
        logs.add(BattleLog(
          turn: turn++,
          action: '${defCard.nameJp} が ${attCard.nameJp} に先制攻撃',
          damage: dmg1,
          attackerHp: attackerHp,
          defenderHp: defenderHp,
          attackingCard: defCard,
          defendingCard: attCard,
          multiplier: m1,
        ));

        if (attackerHp <= 0) break;

        final m2 = getAttributeMultiplier(attCard.attribute, defCard.attribute);
        final dmg2 = _calcDamage(attCard, defCard);
        defenderHp -= dmg2;
        logs.add(BattleLog(
          turn: turn++,
          action: '${attCard.nameJp} が ${defCard.nameJp} に反撃',
          damage: dmg2,
          attackerHp: attackerHp,
          defenderHp: defenderHp,
          attackingCard: attCard,
          defendingCard: defCard,
          multiplier: m2,
        ));

        if (defenderHp <= 0) break;
      }
    }

    // 勝敗判定（HP多い方が勝利、同値は攻撃側勝利）
    final bool attackerWon = attackerHp >= defenderHp;
    return BattleResult(
      attackerWon: attackerWon,
      finalAttackerHp: attackerHp.clamp(0, initialHp),
      finalDefenderHp: defenderHp.clamp(0, initialHp),
      logs: logs,
    );
  }

  static int _calcDamage(PlayCard attacker, PlayCard defender) {
    final multiplier = getAttributeMultiplier(attacker.attribute, defender.attribute);
    final raw = (attacker.attackPower - defender.defensePower).toDouble();
    final dmg = (raw * multiplier).floor();
    return dmg < 1 ? 1 : dmg; // 最低1ダメージ保証
  }
}

class BattleResult {
  final bool attackerWon;
  final int finalAttackerHp;
  final int finalDefenderHp;
  final List<BattleLog> logs;

  BattleResult({
    required this.attackerWon,
    required this.finalAttackerHp,
    required this.finalDefenderHp,
    required this.logs,
  });
}
