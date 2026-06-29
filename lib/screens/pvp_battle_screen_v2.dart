import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import '../models/battle_models.dart';
import '../services/battle_engine.dart';
import '../providers/game_state_provider.dart';
import '../services/sound_service.dart';
import '../widgets/card_widget.dart';
import 'deck_selection_screen_v2.dart';
import 'battle_result_screen_v2.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 属性テーマ定義
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Color _attrColor(String? a) => switch (a) {
      'joy' => const Color(0xFFFFD700),
      'anger' => const Color(0xFFFF3300),
      'sadness' => const Color(0xFF44AAFF),
      _ => Colors.grey,
    };

Color _attrGlow(String? a) => switch (a) {
      'joy' => const Color(0xFFFFAA00),
      'anger' => const Color(0xFFFF2200),
      'sadness' => const Color(0xFF0077FF),
      _ => Colors.grey,
    };

List<Color> _attrBgGradient(String? a) => switch (a) {
      'joy' => [const Color(0xFF1A1200), const Color(0xFF2A1A00)],
      'anger' => [const Color(0xFF1A0300), const Color(0xFF2A0800)],
      'sadness' => [const Color(0xFF000D20), const Color(0xFF000B30)],
      _ => [const Color(0xFF0D0820), const Color(0xFF001018)],
    };

String _attrEmoji(String? a) => switch (a) {
      'joy' => '☀️',
      'anger' => '🔥',
      'sadness' => '🌙',
      _ => '⭐',
    };

String _attrFx(String? a) => switch (a) {
      'joy' => '✨',
      'anger' => '💥',
      'sadness' => '❄️',
      _ => '⚔️',
    };

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// メイン画面
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PvpBattleScreenV2 extends ConsumerStatefulWidget {
  const PvpBattleScreenV2({super.key});

  @override
  ConsumerState<PvpBattleScreenV2> createState() => _PvpBattleScreenV2State();
}

enum _PvpPhase { deckSelect, matching, battle, done }

class _PvpBattleScreenV2State extends ConsumerState<PvpBattleScreenV2>
    with TickerProviderStateMixin {
  _PvpPhase _phase = _PvpPhase.deckSelect;
  List<PlayCard>? _myDeck;
  List<PlayCard>? _opponentDeck;
  String _opponentName = '';
  String _opponentTier = '';
  BattleResult? _result;
  List<BattleLog> _displayedLogs = [];
  int _myHp = 30;
  int _aiHp = 30;
  BattleLog? _latestLog;

  late AnimationController _dotController;
  late AnimationController _pulseController;
  late AnimationController _flashController;
  late AnimationController _damageController;
  late AnimationController _shakeController;
  late AnimationController _auraController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _damageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _auraController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _particleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    _damageController.dispose();
    _shakeController.dispose();
    _auraController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _startMatching() async {
    setState(() => _phase = _PvpPhase.matching);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final allCards = ref.read(allPlayCardsProvider);
    final anger =
        allCards.where((c) => c.attribute == 'anger').skip(2).take(2).toList();
    final sadness = allCards
        .where((c) => c.attribute == 'sadness')
        .skip(1)
        .take(2)
        .toList();
    final joy =
        allCards.where((c) => c.attribute == 'joy').skip(1).take(1).toList();
    _opponentDeck = [...anger, ...sadness, ...joy];
    _opponentName = 'Shadow_Player_47';
    _opponentTier = '🥈シルバー';

    setState(() => _phase = _PvpPhase.battle);
    await _runBattle();
  }

  Future<void> _runBattle() async {
    setState(() {
      _displayedLogs = [];
      _myHp = 30;
      _aiHp = 30;
      _latestLog = null;
    });

    _result = BattleEngine.simulate(_myDeck!, _opponentDeck!);

    for (final log in _result!.logs) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      playSound(SoundEffect.hit);
      _flashController.forward(from: 0);
      _damageController.forward(from: 0);
      _shakeController.forward(from: 0);
      setState(() {
        _displayedLogs.add(log);
        _latestLog = log;
        _myHp = log.attackerHp;
        _aiHp = log.defenderHp;
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BattleResultScreenV2(
          result: _result!,
          isPvP: true,
          myDeck: _myDeck!,
          opponentDeck: _opponentDeck!,
          opponentName: _opponentName,
          opponentTier: _opponentTier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _PvpPhase.deckSelect => DeckSelectionScreenV2(
          title: '⚔️ 攻撃デッキを選択（5枚）',
          onConfirm: (deck) {
            setState(() => _myDeck = deck);
            _startMatching();
          },
        ),
      _PvpPhase.matching => _buildMatchingView(),
      _PvpPhase.battle => _buildBattleView(),
      _PvpPhase.done => const SizedBox.shrink(),
    };
  }

  // ─── マッチング画面 ───────────────────────
  Widget _buildMatchingView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1035), Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(
                    scale: 1 + (_pulseController.value * 0.22),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.8),
                            Colors.amber.withValues(alpha: 0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber
                                .withValues(alpha: 0.5 * _pulseController.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child:
                          const Icon(Icons.shield, size: 60, color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _dotController,
                  builder: (_, snapshot) {
                    final dots =
                        '.' * ((_dotController.value * 3).floor() + 1);
                    return Column(children: [
                      Text('対戦相手を探し中$dots',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('ランクマッチング中...',
                          style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]);
                  },
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _MatchStep(label: 'デッキ選択', done: true),
                    _MatchLine(),
                    const _MatchStep(
                        label: 'マッチング', done: false, active: true),
                    _MatchLine(),
                    const _MatchStep(label: 'バトル', done: false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── バトル画面 ───────────────────────────
  Widget _buildBattleView() {
    final bottom = MediaQuery.of(context).padding.bottom;
    final attackerAttr = _latestLog?.attackingCard?.attribute;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_flashController, _shakeController]),
        builder: (context, child) {
          final shake =
              math.sin(_shakeController.value * math.pi * 8) *
                  7 *
                  (1 - _shakeController.value);
          final flashAlpha = (_flashController.value < 0.5
                  ? _flashController.value * 2
                  : (1 - _flashController.value) * 2) *
              0.38;
          final flashColor = _attrColor(attackerAttr);

          return Transform.translate(
            offset: Offset(shake, 0),
            child: Stack(
              children: [
                // 背景：属性別グラデーション
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ..._attrBgGradient(attackerAttr),
                        const Color(0xFF080518),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // 属性パーティクル
                if (attackerAttr != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (_, child) => CustomPaint(
                        painter: _BattleParticlePainter(
                          tick: _particleController.value,
                          attribute: attackerAttr,
                          flashAmount: _flashController.value,
                        ),
                      ),
                    ),
                  ),
                // ヒットフラッシュ（属性カラー）
                if (flashAlpha > 0)
                  Positioned.fill(
                    child: Container(
                        color: flashColor.withValues(alpha: flashAlpha)),
                  ),
                // コンテンツ
                Column(
                  children: [
                    _ArenaZone(
                      name: _opponentName,
                      tier: _opponentTier,
                      hp: _aiHp,
                      maxHp: 30,
                      deck: _opponentDeck!,
                      isOpponent: true,
                    ),
                    Expanded(child: _buildBattleStage(attackerAttr)),
                    _ArenaZone(
                      name: '👤 あなた',
                      tier: '',
                      hp: _myHp,
                      maxHp: 30,
                      deck: _myDeck!,
                      isOpponent: false,
                      bottomPad: bottom,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── バトルステージ（中央） ───────────────
  Widget _buildBattleStage(String? attackerAttr) {
    final log = _latestLog;
    final accentColor = _attrColor(attackerAttr);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ..._attrBgGradient(attackerAttr),
            const Color(0xFF000510),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFFFF4444), width: 2),
          bottom: BorderSide(color: Color(0xFF4488FF), width: 2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // VS 背景文字
          Text(
            'VS',
            style: TextStyle(
              fontSize: 88,
              fontWeight: FontWeight.w900,
              color: accentColor.withValues(alpha: 0.06),
              letterSpacing: 12,
            ),
          ),
          if (log == null)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('⚔️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('バトル開始...',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
            ])
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ターン + 有利バッジ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.8),
                            accentColor
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 10)
                        ],
                      ),
                      child: Text('TURN ${log.turn}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                    if (log.isAdvantage) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66FFD700), blurRadius: 10)
                          ],
                        ),
                        child: const Text('✨ 属性有利!',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold)),
                      ),
                    ] else if (log.isDisadvantage) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueAccent),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Text('❄️ 属性不利',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // カード対決
                if (log.attackingCard != null && log.defendingCard != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BattleCardDisplay(
                        card: log.attackingCard!,
                        isAttacker: true,
                        auraController: _auraController,
                        flashController: _flashController,
                      ),
                      _AttackEffectWidget(
                        attribute: log.attackingCard!.attribute,
                        multiplier: log.multiplier,
                        flashController: _flashController,
                      ),
                      _BattleCardDisplay(
                        card: log.defendingCard!,
                        isAttacker: false,
                        auraController: _auraController,
                        flashController: _flashController,
                      ),
                    ],
                  ),

                const SizedBox(height: 14),

                // ダメージ数字
                AnimatedBuilder(
                  animation: _damageController,
                  builder: (_, child) {
                    final t = _damageController.value;
                    final yOffset = -40.0 * t;
                    final alpha =
                        t < 0.6 ? 1.0 : (1 - t) / 0.4;
                    final scale = 1.0 + (t < 0.15 ? t * 3.0 : 0.0);
                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: alpha.clamp(0.0, 1.0),
                          child: Text(
                            '${_attrFx(log.attackingCard?.attribute)} -${log.damage}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: _attrColor(log.attackingCard?.attribute),
                              shadows: [
                                Shadow(
                                    color: _attrGlow(
                                            log.attackingCard?.attribute)
                                        .withValues(alpha: 0.9),
                                    blurRadius: 24),
                                const Shadow(color: Colors.white, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

          // ターン進捗（右下）
          if (_displayedLogs.length > 1)
            Positioned(
              bottom: 6,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${_displayedLogs.length} / ${_result?.logs.length ?? '?'} ターン',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 中央攻撃エフェクト
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AttackEffectWidget extends StatelessWidget {
  final String attribute;
  final double multiplier;
  final AnimationController flashController;
  const _AttackEffectWidget(
      {required this.attribute,
      required this.multiplier,
      required this.flashController});

  @override
  Widget build(BuildContext context) {
    final color = _attrColor(attribute);
    final fx = _attrFx(attribute);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: flashController,
            builder: (_, child) {
              final scale = 1.0 + flashController.value * 0.6;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        color.withValues(alpha: 0.08 + flashController.value * 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: color
                            .withValues(alpha: flashController.value * 0.9),
                        blurRadius: 16 + flashController.value * 24,
                        spreadRadius: flashController.value * 10,
                      ),
                    ],
                  ),
                  child: Center(
                      child: Text(fx,
                          style: const TextStyle(fontSize: 28))),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text(
              '×${multiplier == 1.5 ? "1.5" : multiplier == 0.67 ? "0.7" : "1.0"}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// バトル中カード表示（大型・属性オーラ）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _BattleCardDisplay extends StatelessWidget {
  final PlayCard card;
  final bool isAttacker;
  final AnimationController auraController;
  final AnimationController flashController;
  const _BattleCardDisplay({
    required this.card,
    required this.isAttacker,
    required this.auraController,
    required this.flashController,
  });

  @override
  Widget build(BuildContext context) {
    final attr = card.attribute;
    final color = _attrColor(attr);
    final glow = _attrGlow(attr);
    final emoji = _attrEmoji(attr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 攻撃/防御ラベル
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isAttacker ? Colors.redAccent : Colors.blueGrey[700],
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                  color: (isAttacker ? Colors.red : Colors.blueGrey)
                      .withValues(alpha: 0.5),
                  blurRadius: 8)
            ],
          ),
          child: Text(
            isAttacker ? '⚔ 攻撃' : '🛡 防御',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation:
              Listenable.merge([auraController, flashController]),
          builder: (_, child) {
            final auraPulse =
                (math.sin(auraController.value * math.pi * 2) + 1) / 2;
            final flashBoost =
                isAttacker ? flashController.value : 0.0;
            final glowAmount = auraPulse * 0.4 + flashBoost * 0.6;
            // 攻撃カードは前傾み、防御カードは後傾
            final angle =
                isAttacker ? -0.10 + flashBoost * 0.08 : 0.07;

            return Transform.rotate(
              angle: angle,
              child: Container(
                width: 92,
                height: 126,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.38 + glowAmount * 0.2),
                      const Color(0xFF100C28),
                      color.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        color.withValues(alpha: 0.55 + glowAmount * 0.45),
                    width: isAttacker ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(
                          alpha: isAttacker
                              ? 0.35 + glowAmount * 0.55
                              : 0.12 + glowAmount * 0.18),
                      blurRadius: isAttacker
                          ? 16 + glowAmount * 18
                          : 6 + glowAmount * 8,
                      spreadRadius: isAttacker ? glowAmount * 5 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 攻撃カードのみ波動オーラ
                    if (isAttacker)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _CardAuraPainter(
                              color: color,
                              tick: auraController.value +
                                  flashController.value * 0.4,
                            ),
                          ),
                        ),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 38)),
                        const SizedBox(height: 4),
                        Text(
                          card.nameJp.length > 6
                              ? card.nameJp.substring(0, 6)
                              : card.nameJp,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ATK',
                                style: TextStyle(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.85),
                                    fontSize: 7)),
                            const SizedBox(width: 2),
                            Text('${card.attackPower}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('DEF',
                                style: TextStyle(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.85),
                                    fontSize: 7)),
                            const SizedBox(width: 2),
                            Text('${card.defensePower}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// カード波動オーラ CustomPainter
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _CardAuraPainter extends CustomPainter {
  final Color color;
  final double tick;
  _CardAuraPainter({required this.color, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.75;
    for (int i = 0; i < 3; i++) {
      final phase = (tick + i * 0.333) % 1.0;
      final r = maxR * phase;
      final a = (1 - phase) * 0.18;
      paint.color = color.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_CardAuraPainter old) => old.tick != tick;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// バトルパーティクル CustomPainter
// 属性別: joy=星形放射、anger=上昇炎、sadness=落下雫
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _BattleParticlePainter extends CustomPainter {
  final double tick;
  final String attribute;
  final double flashAmount;
  _BattleParticlePainter(
      {required this.tick,
      required this.attribute,
      required this.flashAmount});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final color = _attrColor(attribute);
    final count = attribute == 'anger' ? 14 : 9;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = size.height * (0.2 + rng.nextDouble() * 0.6);
      final phase = (tick + i / count) % 1.0;
      double x, y, radius;

      if (attribute == 'anger') {
        // 炎: 上昇しながら左右にゆれる
        x = baseX + math.sin(phase * math.pi * 3 + i * 1.3) * 18;
        y = baseY - phase * size.height * 0.55;
        radius = 3.5 * (1 - phase * 0.8);
      } else if (attribute == 'joy') {
        // 喜: 中心から星形に放射
        final angle = (i / count) * math.pi * 2 + tick * math.pi * 1.2;
        final r = 50.0 + phase * size.width * 0.32;
        x = size.width / 2 + math.cos(angle) * r;
        y = size.height / 2 + math.sin(angle) * r * 0.6;
        radius = 2.8 * (1 - phase * 0.5);
      } else {
        // 哀: ゆっくり落下する雫
        x = baseX + math.sin(phase * math.pi + i) * 8;
        y = baseY + phase * size.height * 0.28;
        radius = 2.2;
      }

      final alpha =
          ((1 - phase) * 0.28 + flashAmount * 0.18).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BattleParticlePainter old) =>
      old.tick != tick ||
      old.attribute != attribute ||
      old.flashAmount != flashAmount;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// アリーナ プレイヤーゾーン
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ArenaZone extends StatelessWidget {
  final String name;
  final String tier;
  final int hp;
  final int maxHp;
  final List<PlayCard> deck;
  final bool isOpponent;
  final double bottomPad;

  const _ArenaZone({
    required this.name,
    required this.tier,
    required this.hp,
    required this.maxHp,
    required this.deck,
    required this.isOpponent,
    this.bottomPad = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    final hpColor = ratio > 0.5
        ? const Color(0xFF00FF88)
        : ratio > 0.25
            ? Colors.orange
            : Colors.red;
    final bgColor =
        isOpponent ? const Color(0xFF2A0010) : const Color(0xFF001025);
    final accentColor =
        isOpponent ? const Color(0xFFFF4444) : const Color(0xFF4488FF);

    return Container(
      padding: EdgeInsets.fromLTRB(
          12,
          isOpponent ? (MediaQuery.of(context).padding.top + 4) : 10,
          12,
          bottomPad + 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: isOpponent
              ? BorderSide(color: accentColor, width: 1.5)
              : BorderSide.none,
          top: !isOpponent
              ? BorderSide(color: accentColor, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white)),
                    if (tier.isNotEmpty)
                      Text(tier,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: hpColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hpColor, width: 1.5),
                ),
                child: Text(
                  'HP $hp / $maxHp',
                  style: TextStyle(
                      color: hpColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 12, color: Colors.white10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: 12,
                  width:
                      (MediaQuery.of(context).size.width - 24) * ratio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      hpColor.withValues(alpha: 0.7),
                      hpColor
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: hpColor.withValues(alpha: 0.6),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                deck.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6)
                      ],
                    ),
                    child: CardThumbnail(card: deck[i], size: 46),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// マッチングステップ
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MatchStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  const _MatchStep(
      {required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color =
        done ? Colors.green : active ? Colors.amber : Colors.white24;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            done ? '✓' : active ? '●' : '○',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: color, fontSize: 9)),
    ]);
  }
}

class _MatchLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 28,
      height: 2,
      color: Colors.white12,
      margin: const EdgeInsets.only(bottom: 14));
}
