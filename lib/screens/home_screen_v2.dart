import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../widgets/card_widget.dart';
import 'card_creation_screen_v2.dart';
import 'tutorial_battle_screen.dart';
import 'pvp_battle_screen_v2.dart';
import 'defense_deck_screen.dart';
import 'ranking_screen_v2.dart';
import 'tutorial_screen.dart';
import 'achievements_screen.dart';
import 'event_challenges_widget.dart';
import '../models/battle_special_effects.dart';
import '../services/sound_service.dart';
import '../widgets/daily_quests_widget.dart';
import '../widgets/daily_reward_dialog.dart';
import 'collection_screen.dart';

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  bool _dailyShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyReward());
  }

  void _maybeShowDailyReward() {
    if (_dailyShown || !mounted) return;
    _dailyShown = true;
    _showDailyReward();
  }

  void _showDailyReward() {
    final streak = ref.read(loginStreakProvider);
    DailyRewardDialog.show(
      context,
      currentDay: streak,
      onClaim: (coins) {
        final w = ref.read(walletProvider);
        ref.read(walletProvider.notifier).state = w.copyWith(coinBalance: w.coinBalance + coins);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = ref.watch(playerRankProvider);
    final wallet = ref.watch(walletProvider);
    final defenseDeck = ref.watch(defenseDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎮 Card Crown',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 2,
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        actions: [
          // 🔥 連勝ストリーク
          if (wallet.winStreak >= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🔥${wallet.winStreak}連勝',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          // 🪙 コイン残高
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${wallet.coinBalance}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // ティアバッジ
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreenV2())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rank.tierEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      rank.tierLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
            tooltip: '実績',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen())),
            tooltip: 'チュートリアル',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '設定',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // セクション1: ボーナス情報
              _SectionHeader(title: '💰 今日のプレイ状況'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showDailyReward,
                child: _BonusBannerV2(wallet: wallet),
              ),
              const SizedBox(height: 24),

              // セクション1.5: デイリークエスト
              _SectionHeader(title: '📋 デイリークエスト'),
              const SizedBox(height: 8),
              const DailyQuestsWidget(),
              const SizedBox(height: 24),

              // セクション2: メインアクション
              _SectionHeader(title: '⚔️ バトルを始める'),
              const SizedBox(height: 8),
              _MainActionsV2(context: context),
              const SizedBox(height: 24),

              // セクション2.5: イベントチャレンジ
              EventChallengesWidget(challenges: kSampleEventChallenges),
              const SizedBox(height: 24),

              // セクション3: デッキ管理
              _SectionHeader(title: '🛡️ 防衛デッキ（現在の設定）'),
              const SizedBox(height: 8),
              _DefenseDeckSectionV2(defenseDeck: defenseDeck, context: context),
              const SizedBox(height: 24),

              // セクション4: カード管理
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(title: '🎴 あなたのカード'),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionScreen())),
                    icon: const Icon(Icons.grid_view, size: 14),
                    label: const Text('全て見る', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CardSectionV2(context: context),
              SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _BonusBannerV2 extends StatelessWidget {
  final WalletState wallet;
  const _BonusBannerV2({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final todayRatio = wallet.todayWins / 20.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[800]!, Colors.amber[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.amber[800]!.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('本日獲得コイン', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎁 タップでボーナス', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🪙${wallet.todayPoints}/20',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              Text(
                '${wallet.todayWins}/20 勝',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: todayRatio.clamp(0.0, 1.0),
              backgroundColor: Colors.amber[900],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionsV2 extends StatelessWidget {
  final BuildContext context;
  const _MainActionsV2({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PvP ボタン（大きく目立たせる）
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[600]!, Colors.red[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                playSound(SoundEffect.tap);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PvpBattleScreenV2()));
              },
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('⚔️ PvP 対戦', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('勝利で 🪙1 コイン獲得（上限 🪙20/日）', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // AI 練習 + その他（小さめ）
        Row(
          children: [
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorialBattleScreen()),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🤖 AI 練習', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('ボーナスなし', style: TextStyle(color: Colors.blue, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[300]!, width: 1.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreenV2())),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🏆 ランキング', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('順位確認', style: TextStyle(color: Colors.purple, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DefenseDeckSectionV2 extends StatelessWidget {
  final List<dynamic> defenseDeck;
  final BuildContext context;
  const _DefenseDeckSectionV2({required this.defenseDeck, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                defenseDeck.isEmpty ? '未設定' : '${defenseDeck.length}枚設定中',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DefenseDeckScreen()),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('変更', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          defenseDeck.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'タップして防衛デッキを設定してください',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: defenseDeck.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: CardThumbnail(card: defenseDeck[i], size: 70),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CardSectionV2 extends StatelessWidget {
  final BuildContext context;
  const _CardSectionV2({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[50],
      ),
      child: Column(
        children: [
          const Icon(Icons.add_card, size: 48, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            'カードをまだ作成していません',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'AI が自動で画像を生成します',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                playSound(SoundEffect.tap);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CardCreationScreenV2()));
              },
              icon: const Icon(Icons.add),
              label: const Text('カードを作成する（🪙50）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
