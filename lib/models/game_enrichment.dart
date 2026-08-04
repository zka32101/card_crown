// ゲーム性をリッチにするための機能群

class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlockedAt,
  });
}

class AchievementProgress {
  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final String? reward; // ボーナス説明
  final bool isUnlocked;

  AchievementProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    this.reward,
    this.isUnlocked = false,
  });

  double get percent => (progress / target).clamp(0.0, 1.0);
}

class DailyStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastBattleDate;
  final int bonusMultiplier; // ストリーク ×1.0 から ×1.5 まで

  DailyStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastBattleDate,
    this.bonusMultiplier = 1,
  });
}

// バッジ定義
final kBadgeDefinitions = [
  // スターターバッジ
  Badge(
    id: 'first_victory',
    name: '初勝利',
    emoji: '🎉',
    description: 'はじめて PvP 対戦に勝利',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'first_card_created',
    name: 'カード職人',
    emoji: '🎨',
    description: '自分のカードを初めて作成',
    unlockedAt: DateTime.now(),
  ),

  // 戦績バッジ
  Badge(
    id: 'ten_victories',
    name: '十勝士',
    emoji: '🥈',
    description: 'PvP で 10 勝以上',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'fifty_victories',
    name: '五十勝将',
    emoji: '🥇',
    description: 'PvP で 50 勝以上',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'hundred_victories',
    name: '百勝大将',
    emoji: '👑',
    description: 'PvP で 100 勝以上',
    unlockedAt: DateTime.now(),
  ),

  // レーティングバッジ
  Badge(
    id: 'bronze_rank',
    name: '青銅ランク',
    emoji: '🥉',
    description: 'ELO 500pt 到達',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'silver_rank',
    name: '銀メダル',
    emoji: '🥈',
    description: 'ELO 1000pt 到達',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'gold_rank',
    name: '金メダル',
    emoji: '🥇',
    description: 'ELO 1500pt 到達',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'platinum_rank',
    name: 'プラチナランク',
    emoji: '💎',
    description: 'ELO 2000pt 到達',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'diamond_rank',
    name: 'ダイヤモンドランク',
    emoji: '👑',
    description: 'ELO 2500pt 到達',
    unlockedAt: DateTime.now(),
  ),

  // カード関連バッジ
  Badge(
    id: 'five_cards',
    name: 'カードコレクター',
    emoji: '🎴',
    description: '5 枚のカードを作成',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'all_attributes',
    name: '属性マスター',
    emoji: '🌈',
    description: '3 つの属性でカードを作成',
    unlockedAt: DateTime.now(),
  ),

  // ストリークバッジ
  Badge(
    id: 'seven_day_streak',
    name: 'デイリープレイヤー',
    emoji: '🔥',
    description: '7 日連続でプレイ',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'thirty_day_streak',
    name: 'つわもの',
    emoji: '⭐',
    description: '30 日連続でプレイ',
    unlockedAt: DateTime.now(),
  ),

  // 特殊バッジ
  Badge(
    id: 'comeback_win',
    name: 'ビッグコメバック',
    emoji: '💪',
    description: 'HP 1 の状態から勝利',
    unlockedAt: DateTime.now(),
  ),
  Badge(
    id: 'perfect_victory',
    name: 'ノーダメージ勝利',
    emoji: '🛡️',
    description: 'ダメージを受けずに勝利',
    unlockedAt: DateTime.now(),
  ),
];

// 実績定義
List<AchievementProgress> getAchievementProgress({
  required int wins,
  required int losses,
  required int rating,
  required int cardsCreated,
  required int dailyStreak,
  required List<Badge> unlockedBadges,
}) {
  return [
    AchievementProgress(
      id: 'win_10',
      title: '戦勝 10',
      description: 'PvP で 10 勝達成',
      progress: wins,
      target: 10,
      reward: 'バッジ: 十勝士 🥈',
      isUnlocked: unlockedBadges.any((b) => b.id == 'ten_victories'),
    ),
    AchievementProgress(
      id: 'win_50',
      title: '戦勝 50',
      description: 'PvP で 50 勝達成',
      progress: wins,
      target: 50,
      reward: 'バッジ: 五十勝将 🥇',
      isUnlocked: unlockedBadges.any((b) => b.id == 'fifty_victories'),
    ),
    AchievementProgress(
      id: 'rating_1000',
      title: 'ELO 1000',
      description: 'ELO レート 1000pt 達成',
      progress: rating,
      target: 1000,
      reward: 'バッジ: 銀メダル 🥈',
      isUnlocked: unlockedBadges.any((b) => b.id == 'silver_rank'),
    ),
    AchievementProgress(
      id: 'rating_1500',
      title: 'ELO 1500',
      description: 'ELO レート 1500pt 達成',
      progress: rating,
      target: 1500,
      reward: 'バッジ: 金メダル 🥇',
      isUnlocked: unlockedBadges.any((b) => b.id == 'gold_rank'),
    ),
    AchievementProgress(
      id: 'cards_5',
      title: 'カード 5 枚',
      description: '5 枚のカードを作成',
      progress: cardsCreated,
      target: 5,
      reward: 'バッジ: カードコレクター 🎴',
      isUnlocked: unlockedBadges.any((b) => b.id == 'five_cards'),
    ),
    AchievementProgress(
      id: 'streak_7',
      title: '7 日ストリーク',
      description: '7 日連続でバトル',
      progress: dailyStreak,
      target: 7,
      reward: 'バッジ: デイリープレイヤー 🔥',
      isUnlocked: unlockedBadges.any((b) => b.id == 'seven_day_streak'),
    ),
  ];
}
