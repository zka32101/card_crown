import '../models/battle_models.dart';
import '../models/user_card.dart';

// 決定論的バトルシミュレーション（乱数なし）
class BattleEngine {
  static const int initialHp = 30;
  // 「属性の国」移住ボーナス：移住先属性のカードで攻撃した際に加算される倍率
  static const double migrationBonus = 0.15;

  static BattleResult simulate(
    List<PlayCard> attackerDeck,
    List<PlayCard> defenderDeck, {
    // attackerDeck側のプレイヤーが移住済みの属性（null = 移住なし）
    String? migratedAttribute,
  }) {
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
        // attCard（attackerDeck側）が攻撃 → 移住ボーナス対象
        final m1 = _effectiveMultiplier(attCard.attribute, defCard.attribute,
            boosted: attCard.attribute == migratedAttribute);
        final dmg1 = _damageFromMultiplier(attCard, defCard, m1);
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

        // defCard（defenderDeck側）が反撃 → 移住ボーナス対象外
        final m2 = _effectiveMultiplier(defCard.attribute, attCard.attribute, boosted: false);
        final dmg2 = _damageFromMultiplier(defCard, attCard, m2);
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
        // defCard（defenderDeck側）が先制 → 移住ボーナス対象外
        final m1 = _effectiveMultiplier(defCard.attribute, attCard.attribute, boosted: false);
        final dmg1 = _damageFromMultiplier(defCard, attCard, m1);
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

        // attCard（attackerDeck側）が反撃 → 移住ボーナス対象
        final m2 = _effectiveMultiplier(attCard.attribute, defCard.attribute,
            boosted: attCard.attribute == migratedAttribute);
        final dmg2 = _damageFromMultiplier(attCard, defCard, m2);
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

  static double _effectiveMultiplier(String attackerAttribute, String defenderAttribute,
      {required bool boosted}) {
    final base = getAttributeMultiplier(attackerAttribute, defenderAttribute);
    return boosted ? base + migrationBonus : base;
  }

  static int _damageFromMultiplier(PlayCard attacker, PlayCard defender, double multiplier) {
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
