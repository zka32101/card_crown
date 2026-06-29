import 'package:flutter/material.dart';
import '../models/user_card.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 属性・レアリティ共通テーマ
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Color rarityColor(CardRarity r) => switch (r) {
      CardRarity.n => const Color(0xFF9E9E9E),
      CardRarity.r => const Color(0xFF42A5F5),
      CardRarity.sr => const Color(0xFFAB47BC),
      CardRarity.ur => const Color(0xFFFFD700),
    };

Color _attrPrimary(String? a) => switch (a) {
      'joy' => const Color(0xFFFFB300),
      'anger' => const Color(0xFFE53935),
      'sadness' => const Color(0xFF1E88E5),
      _ => const Color(0xFF757575),
    };

String _attrEmoji(String? a) => switch (a) {
      'joy' => '☀️',
      'anger' => '🔥',
      'sadness' => '🌙',
      _ => '⭐',
    };

String _attrLabel(String? a) => switch (a) {
      'joy' => '喜',
      'anger' => '怒',
      'sadness' => '哀',
      _ => '',
    };

LinearGradient _attrArtGradient(String? a) => switch (a) {
      'joy' => const LinearGradient(
          colors: [Color(0xFF3D2800), Color(0xFF7A4F00), Color(0xFF3D2800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      'anger' => const LinearGradient(
          colors: [Color(0xFF3D0000), Color(0xFF7A1500), Color(0xFF2A0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      'sadness' => const LinearGradient(
          colors: [Color(0xFF000D28), Color(0xFF00204A), Color(0xFF000D28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      _ => const LinearGradient(
          colors: [Color(0xFF1A1035), Color(0xFF0D0820)],
        ),
    };

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// フルカードウィジェット
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CardWidget extends StatelessWidget {
  final PlayCard card;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    this.size = 150,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attr = card.attribute;
    final accent = _attrPrimary(attr);
    final rColor = rarityColor(card.rarity);
    final isUR = card.rarity == CardRarity.ur;
    final isSR = card.rarity == CardRarity.sr;

    final borderWidth = isUR
        ? 2.5
        : isSR
            ? 2.0
            : isSelected
                ? 2.5
                : 1.5;
    final borderColor = isSelected ? Colors.white : rColor;
    final glowAlpha = isUR
        ? 0.65
        : isSR
            ? 0.45
            : isSelected
                ? 0.55
                : 0.18;
    final glowRadius =
        isUR ? 18.0 : isSR ? 12.0 : isSelected ? 14.0 : 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: glowAlpha),
              blurRadius: glowRadius,
              spreadRadius: isUR ? 2 : 0,
            ),
          ],
          // ダーク背景 + 属性グラデーション
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1530),
              accent.withValues(alpha: 0.10),
              const Color(0xFF0D0820),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(card: card, accent: accent),
                  _ArtArea(card: card, accent: accent),
                  _TypeBar(card: card, accent: accent),
                  _StatsSection(card: card),
                ],
              ),
              // UR ホイルシマーオーバーレイ
              if (isUR)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.07),
                            const Color(0xFFFFD700).withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ヘッダー（属性色帯 + 名前 + コスト） ───
class _Header extends StatelessWidget {
  final PlayCard card;
  final Color accent;
  const _Header({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.75)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Text(_attrEmoji(card.attribute),
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              card.nameJp,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // コストをドットで表示
          Row(
            children: List.generate(
              card.cost,
              (_) => Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── アートエリア ───
class _ArtArea extends StatelessWidget {
  final PlayCard card;
  final Color accent;
  const _ArtArea({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: card.imageUrl.isNotEmpty
              ? Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, err, stack) =>
                      _ArtPlaceholder(card: card),
                )
              : _ArtPlaceholder(card: card),
        ),
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  final PlayCard card;
  const _ArtPlaceholder({required this.card});

  @override
  Widget build(BuildContext context) {
    final emoji = _attrEmoji(card.attribute);
    final label = _attrLabel(card.attribute);
    return Container(
      decoration: BoxDecoration(gradient: _attrArtGradient(card.attribute)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 大きな背景絵文字（薄く）
          Positioned(
            bottom: -8,
            right: -8,
            child: Text(
              emoji,
              style: TextStyle(
                  fontSize: 56,
                  color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── タイプバー（属性ラベル + レアリティ） ───
class _TypeBar extends StatelessWidget {
  final PlayCard card;
  final Color accent;
  const _TypeBar({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final rColor = rarityColor(card.rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.35), width: 0.5),
          bottom:
              BorderSide(color: accent.withValues(alpha: 0.35), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _attrLabel(card.attribute),
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: rColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: rColor.withValues(alpha: 0.8), width: 0.8),
            ),
            child: Text(
              card.rarityLabel,
              style: TextStyle(
                fontSize: 8,
                color: rColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ステータス ───
class _StatsSection extends StatelessWidget {
  final PlayCard card;
  const _StatsSection({required this.card});

  @override
  Widget build(BuildContext context) {
    final maxStat = (card.cost * 8 + 12).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
      child: Column(
        children: [
          _StatRow(
            icon: '⚔',
            value: card.attackPower,
            maxVal: maxStat,
            color: const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 3),
          _StatRow(
            icon: '🛡',
            value: card.defensePower,
            maxVal: maxStat,
            color: const Color(0xFF4DD0E1),
          ),
          const SizedBox(height: 3),
          _StatRow(
            icon: '⚡',
            value: card.speed,
            maxVal: maxStat,
            color: const Color(0xFFCE93D8),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon;
  final int value;
  final double maxVal;
  final Color color;
  const _StatRow(
      {required this.icon,
      required this.value,
      required this.maxVal,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(icon, style: const TextStyle(fontSize: 9)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient:
                        LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// サムネイル（デッキ選択・バトルゾーン用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CardThumbnail extends StatelessWidget {
  final PlayCard card;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const CardThumbnail({
    super.key,
    required this.card,
    this.size = 80,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _attrPrimary(card.attribute);
    final rColor = rarityColor(card.rarity);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size * 1.28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white : accent.withValues(alpha: 0.85),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isSelected ? 0.7 : 0.3),
                  blurRadius: isSelected ? 12 : 5,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.35),
                  const Color(0xFF0D0820),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Column(
                children: [
                  Expanded(
                    child: card.imageUrl.isNotEmpty
                        ? Image.network(
                            card.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, err, stack) => Center(
                              child: Text(_attrEmoji(card.attribute),
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                                gradient: _attrArtGradient(card.attribute)),
                            child: Center(
                              child: Text(_attrEmoji(card.attribute),
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                  ),
                  // 名前バー
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 2),
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Text(
                      card.nameJp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 選択チェック
          if (isSelected)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 10, color: Colors.black),
              ),
            ),
          // レアリティバッジ（左下）
          if (card.rarity != CardRarity.n)
            Positioned(
              bottom: 20,
              left: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: rColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  card.rarityLabel,
                  style: const TextStyle(
                      fontSize: 6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
