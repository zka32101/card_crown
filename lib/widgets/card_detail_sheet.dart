import 'package:flutter/material.dart';
import '../models/user_card.dart';
import '../theme/kingdom_theme.dart';
import '../l10n/app_localizations.dart';
import 'card_widget.dart';

/// カード詳細をボトムシートで表示する（コレクション/デッキ選択などから共通利用）
void showCardDetailSheet(BuildContext context, PlayCard card) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CardDetailSheet(card: card),
  );
}

class CardDetailSheet extends StatelessWidget {
  final PlayCard card;
  const CardDetailSheet({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final attrColor = Kingdom.attributeColor(card.attribute);
    final rc = rarityColor(card.rarity);

    return Container(
      padding: const EdgeInsets.fromLTRB(Kingdom.spaceXl, Kingdom.spaceLg, Kingdom.spaceXl, Kingdom.spaceXxxl),
      decoration: BoxDecoration(
        color: Kingdom.nightDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: rc, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Kingdom.parchment.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: Kingdom.spaceXl),

          Row(
            children: [
              // カードプレビュー
              SizedBox(width: 120, child: CardWidget(card: card, size: 120)),
              const SizedBox(width: Kingdom.spaceXl),
              // 詳細情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceSm, vertical: 3),
                          decoration: BoxDecoration(color: rc, borderRadius: BorderRadius.circular(6)),
                          child: Text(card.rarityLabel, style: TextStyle(color: Kingdom.night, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: Kingdom.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceSm, vertical: 3),
                          decoration: BoxDecoration(color: attrColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: attrColor)),
                          child: Text(_attrLabel(t, card.attribute), style: TextStyle(color: attrColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Kingdom.spaceSm),
                    Text(card.nameJp,
                        style: TextStyle(
                            fontFamily: Kingdom.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: Kingdom.parchment)),
                    const SizedBox(height: Kingdom.spaceXs),
                    Text(t.collection_costTypeLine(card.cost, _typeLabel(t, card.getCardType())),
                        style: TextStyle(color: Kingdom.parchment.withValues(alpha: 0.5), fontSize: 12)),
                    const SizedBox(height: 14),
                    _statDetail(t.card_attack, card.attackPower, Kingdom.angerCrimson),
                    const SizedBox(height: 6),
                    _statDetail(t.card_defense, card.defensePower, Kingdom.sadnessIndigo),
                    const SizedBox(height: 6),
                    _statDetail(t.card_speed, card.speed, Kingdom.joyGold),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Kingdom.spaceLg),
          // 相性情報
          Container(
            padding: const EdgeInsets.all(Kingdom.spaceMd),
            decoration: BoxDecoration(color: attrColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _advantageChip(t.collection_advantageLabel, _advantage(t, card.attribute), Kingdom.joyGold),
                _advantageChip(t.collection_disadvantageLabel, _disadvantage(t, card.attribute), Kingdom.angerCrimson),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDetail(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: TextStyle(fontSize: Kingdom.textCaption, color: color, fontWeight: FontWeight.bold))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 40).clamp(0.0, 1.0),
              backgroundColor: Kingdom.parchment.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Kingdom.parchment)),
      ],
    );
  }

  Widget _advantageChip(String label, String target, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(target, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Kingdom.parchment)),
      ],
    );
  }

  String _attrLabel(AppLocalizations t, String a) => switch (a) {
        'joy' => '☀️ ${t.attribute_joy}',
        'anger' => '🔥 ${t.attribute_anger}',
        _ => '🌙 ${t.attribute_sadness}',
      };
  String _typeLabel(AppLocalizations t, String type) => switch (type) {
        'attack' => t.collection_typeAttack,
        'defense' => t.collection_typeDefense,
        'speed' => t.collection_typeSpeed,
        _ => t.collection_typeBalance,
      };
  String _advantage(AppLocalizations t, String a) => switch (a) {
        'joy' => t.collection_strongAgainst('🔥 ${t.attribute_anger}'),
        'anger' => t.collection_strongAgainst('🌙 ${t.attribute_sadness}'),
        _ => t.collection_strongAgainst('☀️ ${t.attribute_joy}'),
      };
  String _disadvantage(AppLocalizations t, String a) => switch (a) {
        'joy' => t.collection_weakAgainst('🌙 ${t.attribute_sadness}'),
        'anger' => t.collection_weakAgainst('☀️ ${t.attribute_joy}'),
        _ => t.collection_weakAgainst('🔥 ${t.attribute_anger}'),
      };
}
