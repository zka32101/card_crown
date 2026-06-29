import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import '../providers/game_state_provider.dart';
import '../widgets/card_widget.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> with SingleTickerProviderStateMixin {
  String? _attrFilter;      // null = 全て
  CardRarity? _rarityFilter;
  String _sort = 'rarity';  // 'rarity' | 'attr' | 'cost'
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(allPlayCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎴 カードコレクション'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rarity', child: Text('レアリティ順')),
              const PopupMenuItem(value: 'attr', child: Text('属性順')),
              const PopupMenuItem(value: 'cost', child: Text('コスト順')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'シードカード'),
            Tab(text: 'マイカード'),
          ],
        ),
      ),
      body: Column(
        children: [
          // フィルターバー
          _FilterBar(
            attrFilter: _attrFilter,
            rarityFilter: _rarityFilter,
            onAttrChanged: (v) => setState(() => _attrFilter = v),
            onRarityChanged: (v) => setState(() => _rarityFilter = v),
          ),

          // カードグリッド
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // シードカード
                _CardGrid(
                  cards: _filtered(allCards.where((c) => c.isSeedCard).toList()),
                ),
                // マイカード（現状はシードから未所持分を除外 ― Firebase 接続後は Firestore から取得）
                _CardGrid(
                  cards: _filtered(allCards.where((c) => !c.isSeedCard).toList()),
                  emptyMessage: 'まだカードを作成していません\nカード作成画面から新しいカードを作ろう！',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PlayCard> _filtered(List<PlayCard> cards) {
    var result = cards.where((c) {
      if (_attrFilter != null && c.attribute != _attrFilter) return false;
      if (_rarityFilter != null && c.rarity != _rarityFilter) return false;
      return true;
    }).toList();

    result.sort((a, b) => switch (_sort) {
      'attr' => a.attribute.compareTo(b.attribute),
      'cost' => b.cost.compareTo(a.cost),
      _ => b.rarity.index.compareTo(a.rarity.index), // rarity: UR→SR→R→N
    });

    return result;
  }
}

class _FilterBar extends StatelessWidget {
  final String? attrFilter;
  final CardRarity? rarityFilter;
  final void Function(String?) onAttrChanged;
  final void Function(CardRarity?) onRarityChanged;

  const _FilterBar({
    required this.attrFilter,
    required this.rarityFilter,
    required this.onAttrChanged,
    required this.onRarityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple[50],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // 属性フィルタ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('全て', attrFilter == null, () => onAttrChanged(null), Colors.grey),
                const SizedBox(width: 6),
                _chip('☀️ 喜', attrFilter == 'joy', () => onAttrChanged('joy'), const Color(0xFFFFD700)),
                const SizedBox(width: 6),
                _chip('🔥 怒', attrFilter == 'anger', () => onAttrChanged('anger'), const Color(0xFFE74C3C)),
                const SizedBox(width: 6),
                _chip('🌙 哀', attrFilter == 'sadness', () => onAttrChanged('sadness'), const Color(0xFF3498DB)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // レアリティフィルタ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('全レア', rarityFilter == null, () => onRarityChanged(null), Colors.grey),
                const SizedBox(width: 6),
                _chip('UR', rarityFilter == CardRarity.ur, () => onRarityChanged(CardRarity.ur), const Color(0xFFFFD700)),
                const SizedBox(width: 6),
                _chip('SR', rarityFilter == CardRarity.sr, () => onRarityChanged(CardRarity.sr), const Color(0xFF9B59B6)),
                const SizedBox(width: 6),
                _chip('R', rarityFilter == CardRarity.r, () => onRarityChanged(CardRarity.r), const Color(0xFF3498DB)),
                const SizedBox(width: 6),
                _chip('N', rarityFilter == CardRarity.n, () => onRarityChanged(CardRarity.n), Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<PlayCard> cards;
  final String? emptyMessage;

  const _CardGrid({required this.cards, this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎴', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                emptyMessage ?? 'カードが見つかりません',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        return GestureDetector(
          onTap: () => _showCardDetail(context, card),
          child: CardWidget(card: card, size: double.infinity),
        );
      },
    );
  }

  void _showCardDetail(BuildContext context, PlayCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailSheet(card: card),
    );
  }
}

class _CardDetailSheet extends StatelessWidget {
  final PlayCard card;
  const _CardDetailSheet({required this.card});

  @override
  Widget build(BuildContext context) {
    final attrColor = switch (card.attribute) {
      'joy' => const Color(0xFFFFD700),
      'anger' => const Color(0xFFE74C3C),
      _ => const Color(0xFF3498DB),
    };
    final rc = rarityColor(card.rarity);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: rc, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Row(
            children: [
              // カードプレビュー
              SizedBox(width: 120, child: CardWidget(card: card, size: 120)),
              const SizedBox(width: 20),
              // 詳細情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: rc, borderRadius: BorderRadius.circular(6)),
                          child: Text(card.rarityLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: attrColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: attrColor)),
                          child: Text(_attrLabel(card.attribute), style: TextStyle(color: attrColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(card.nameJp, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('コスト ${card.cost}  •  ${_typeLabel(card.getCardType())}型',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 14),
                    _statDetail('攻撃力', card.attackPower, const Color(0xFFFF6347)),
                    const SizedBox(height: 6),
                    _statDetail('防御力', card.defensePower, const Color(0xFF4169E1)),
                    const SizedBox(height: 6),
                    _statDetail('速度', card.speed, const Color(0xFF9370DB)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // 相性情報
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: attrColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _advantageChip('有利', _advantage(card.attribute), Colors.green),
                _advantageChip('不利', _disadvantage(card.attribute), Colors.red),
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
        SizedBox(width: 40, child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (value / 40).clamp(0.0, 1.0), backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
          ),
        ),
        const SizedBox(width: 6),
        Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _advantageChip(String label, String target, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(target, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _attrLabel(String a) => switch (a) { 'joy' => '☀️ 喜', 'anger' => '🔥 怒', _ => '🌙 哀' };
  String _typeLabel(String t) => switch (t) { 'attack' => '攻撃', 'defense' => '防御', 'speed' => '速度', _ => 'バランス' };
  String _advantage(String a) => switch (a) { 'joy' => '🔥 怒 に強い', 'anger' => '🌙 哀 に強い', _ => '☀️ 喜 に強い' };
  String _disadvantage(String a) => switch (a) { 'joy' => '🌙 哀 に弱い', 'anger' => '☀️ 喜 に弱い', _ => '🔥 怒 に弱い' };
}
