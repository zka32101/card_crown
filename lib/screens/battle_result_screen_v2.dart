import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import '../providers/game_state_provider.dart';
import '../services/battle_engine.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_painter.dart';
import '../widgets/daily_quests_widget.dart';

class BattleResultScreenV2 extends ConsumerStatefulWidget {
  final BattleResult result;
  final bool isPvP;
  final List<PlayCard> myDeck;
  final List<PlayCard> opponentDeck;
  final String? opponentName;
  final String? opponentTier;

  const BattleResultScreenV2({
    super.key,
    required this.result,
    required this.isPvP,
    required this.myDeck,
    required this.opponentDeck,
    this.opponentName,
    this.opponentTier,
  });

  @override
  ConsumerState<BattleResultScreenV2> createState() => _BattleResultScreenV2State();
}

class _BattleResultScreenV2State extends ConsumerState<BattleResultScreenV2> {
  int _streakBonus = 0;
  int _newStreak = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playSound(widget.result.attackerWon ? SoundEffect.victory : SoundEffect.defeat);
      _updateStreak();
      _updateQuests();
    });
  }

  void _updateStreak() {
    final w = ref.read(walletProvider);
    if (widget.result.attackerWon) {
      _newStreak = w.winStreak + 1;
      final bonus = ref.read(walletProvider).copyWith(winStreak: _newStreak).streakBonus;
      _streakBonus = bonus > (w.copyWith(winStreak: w.winStreak).streakBonus) ? bonus : 0;
      ref.read(walletProvider.notifier).state = w.copyWith(
        winStreak: _newStreak,
        coinBalance: w.coinBalance + (_streakBonus),
      );
    } else {
      _newStreak = 0;
      ref.read(walletProvider.notifier).state = w.copyWith(winStreak: 0);
    }
    setState(() {});
  }

  void _updateQuests() {
    final quests = ref.read(dailyQuestsProvider);
    final updated = quests.map((q) {
      if (q.type == QuestType.battle && q.progress < q.target) {
        return q.copyWith(progress: q.progress + 1);
      }
      if (q.type == QuestType.win && widget.result.attackerWon && q.progress < q.target) {
        return q.copyWith(progress: q.progress + 1);
      }
      return q;
    }).toList();
    ref.read(dailyQuestsProvider.notifier).state = updated;
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.result.attackerWon;
    final bgColor = isWin ? Colors.green : Colors.red;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor[900]!, bgColor[700]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // 勝利時の紙吹雪
            if (isWin) const Positioned.fill(child: ConfettiOverlay()),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 勝敗表示
                  _buildResultHeader(isWin),

                  const SizedBox(height: 30),

                  // 統計情報
                  _buildStatsPanel(),

                  const SizedBox(height: 24),

                  // デッキ比較
                  _buildDeckComparison(),

                  const SizedBox(height: 24),

                  // 連勝ストリーク（勝利時）
                  if (isWin && _newStreak > 1) ...[
                    _buildStreakPanel(),
                    const SizedBox(height: 24),
                  ],

                  // ボーナス情報（PvP の場合）
                  if (widget.isPvP) ...[
                    _buildBonusInfo(),
                    const SizedBox(height: 24),
                  ],

                  // ボタン群
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // もう一度バトル
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('もう一度バトル'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: bgColor[900],
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ホームに戻る
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                            icon: const Icon(Icons.home, color: Colors.white70),
                            label: const Text('ホームに戻る', style: TextStyle(color: Colors.white70)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader(bool isWin) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Text(
                isWin ? '🎉' : '😢',
                style: const TextStyle(fontSize: 80),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          isWin ? '勝利！' : '敗北',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 4),
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isWin ? 'おめでとうございます！' : 'また挑戦してください',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'バトル統計',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(
                  label: 'ターン数',
                  value: '${widget.result.logs.length}',
                  icon: '⏱️',
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                _StatBox(
                  label: '総ダメージ',
                  value: '${widget.result.logs.fold<int>(0, (prev, log) => prev + log.damage)}',
                  icon: '⚔️',
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                _StatBox(
                  label: '残りHP',
                  value: '${widget.result.attackerWon ? widget.result.finalAttackerHp : widget.result.finalDefenderHp}',
                  icon: '❤️',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '使用デッキ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final card in widget.myDeck)
                  Column(
                    children: [
                      Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: _getCardGradient(card.attribute),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(card.attribute == 'joy' ? '☀️' : card.attribute == 'anger' ? '🔥' : '🌙',
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.attackPower}/${card.defensePower}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPanel() {
    final streakEmoji = _newStreak >= 7 ? '🔥🔥🔥' : _newStreak >= 5 ? '🔥🔥' : '🔥';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange[800]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 12)],
        ),
        child: Row(
          children: [
            Text(streakEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_newStreak連勝中！', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_streakBonus > 0)
                    Text('+🪙$_streakBonus ストリークボーナス獲得!', style: const TextStyle(color: Colors.yellowAccent, fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                Text('$_newStreak', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('連勝', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusInfo() {
    const bonusAmount = 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber[700]!, Colors.amber[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              '💰 PvP ボーナス',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '本日の対戦勝利',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '+🪙$bonusAmount',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '（1日上限 🪙20、次のリセット: JST 00:00）',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCardGradient(String attribute) {
    switch (attribute) {
      case 'joy':
        return LinearGradient(
          colors: [Colors.yellow[600]!, Colors.amber[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'anger':
        return LinearGradient(
          colors: [Colors.red[600]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.blue[600]!, Colors.indigo[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
