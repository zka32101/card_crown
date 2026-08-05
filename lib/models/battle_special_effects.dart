// バトルの特殊効果・ゲーム性拡張

enum SpecialEffect {
  critical,       // クリティカル（1.5倍ダメージ）
  stun,           // スタン（1ターン行動不可）
  shield,         // シールド（次のダメージ50%軽減）
  regen,          // 再生（毎ターンHP回復）
  berserk,        // 暴走（攻撃2倍だが防御半減）
  dodge,          // 回避（攻撃を完全に無効化）
  counter,        // カウンター（反撃でダメージ返す）
}

class SpecialEventOccurrence {
  final SpecialEffect effect;
  final int turn;
  final String description;
  final double probability; // 発動確率（0.0-1.0）

  SpecialEventOccurrence({
    required this.effect,
    required this.turn,
    required this.description,
    required this.probability,
  });
}

// カード進化システム
class CardEvolution {
  final String cardId;
  final int evolutionLevel; // 0 = 無進化, 1-3 = 進化段階
  final String? evolvedImageUrl;
  final int evolutionCost; // ¥進化コスト
  final Map<String, int> statBonuses; // {'attack': 5, 'defense': 3, ...}

  CardEvolution({
    required this.cardId,
    required this.evolutionLevel,
    this.evolvedImageUrl,
    this.evolutionCost = 0,
    this.statBonuses = const {},
  });
}

// シーズンシステム
class Season {
  final String id;
  final String name;
  final String emoji;
  final DateTime startDate;
  final DateTime endDate;
  final String reward; // シーズン終了時のリワード
  final int rewardMultiplier; // ポイント倍率

  Season({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDate,
    required this.endDate,
    required this.reward,
    this.rewardMultiplier = 1,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

// イベントチャレンジ
class EventChallenge {
  final String id;
  final String title;
  final String description;
  final String reward;
  final int goalValue;
  final String goalType; // 'wins', 'damage_dealt', 'special_effects', etc.
  final DateTime deadline;

  EventChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.goalValue,
    required this.goalType,
    required this.deadline,
  });

  bool get isActive => DateTime.now().isBefore(deadline);
}

// カード融合システム
class CardFusion {
  final String baseCardId;
  final List<String> sacrificeCardIds; // 融合に使うカード
  final Map<String, int> resultStats; // 融合後のステータス
  final String? resultImageUrl;
  final int fusionCost; // ¥融合コスト

  CardFusion({
    required this.baseCardId,
    required this.sacrificeCardIds,
    required this.resultStats,
    this.resultImageUrl,
    this.fusionCost = 500,
  });
}

// サンプルシーズンデータ
final kCurrentSeason = Season(
  id: 's2025_01',
  name: '2025 Winter Season',
  emoji: '❄️',
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 3, 31),
  reward: '限定バッジ + ¥500 ボーナス',
  rewardMultiplier: 2,
);

// サンプルイベントチャレンジの多言語文言は、AppLocalizations経由で解決するため
// event_challenges_widget.dart 側の buildSampleEventChallenges(t) に定義している
// （このモデルファイル自体はUIに依存しない純粋なデータクラス定義に留める）。
