import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/card_widget.dart';
import '../widgets/card_reveal_dialog.dart';
import '../models/user_card.dart';
import '../models/card_design_words.dart';
import '../services/functions_service.dart';
import '../services/purchase_service.dart';
import '../widgets/daily_quests_widget.dart';

class CardCreationScreenV2 extends ConsumerStatefulWidget {
  const CardCreationScreenV2({super.key});

  @override
  ConsumerState<CardCreationScreenV2> createState() => _CardCreationScreenV2State();
}

class _CardCreationScreenV2State extends ConsumerState<CardCreationScreenV2> {
  int _step = 0;
  final List<String> _selectedDesignWords = []; // カードデザイン選択
  String? _attribute;
  int? _cost;
  int _attack = 0;
  int _defense = 0;
  int _speed = 0;
  String _tone = 'cool';
  List<String> _nameCandidates = [];
  String? _selectedName;
  bool _isGeneratingName = false;

  int get _budget => switch (_cost ?? 1) { 1 => 20, 2 => 25, 3 => 30, 4 => 35, _ => 40 };
  int get _remaining => _budget - _attack - _defense - _speed;
  bool get _isParamValid => _remaining == 0 && _attack > 0 && _defense > 0 && _speed > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('カード作成 - ステップ ${_step + 1}/6'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_step + 1) / 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                minHeight: 4,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ステップ表示
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(6, (i) {
                  final isActive = i == _step;
                  final isDone = i < _step;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green : isActive ? Colors.amber[700] : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isDone ? '✓' : '${i + 1}',
                              style: TextStyle(
                                color: isDone || isActive ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['デザイン', '属性', 'コスト', 'パラメータ', 'トーン', '命名'][i],
                          style: TextStyle(fontSize: 11, color: isActive ? Colors.amber[700] : Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: switch (_step) {
                  0 => _buildDesignStep(),
                  1 => _buildAttributeStep(),
                  2 => _buildCostStep(),
                  3 => _buildParameterStep(),
                  4 => _buildToneStep(),
                  5 => _buildNamingStep(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),

            // ボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('← 戻る'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _buildNextButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('カードデザイン（3つ選択）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('この 3 つの言葉がカードのデザインになります', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        // 選択済み言葉表示
        if (_selectedDesignWords.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ 選択済み（${_selectedDesignWords.length}/3）',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedDesignWords.map((word) {
                    return Chip(
                      label: Text(word),
                      onDeleted: () {
                        setState(() => _selectedDesignWords.remove(word));
                      },
                      backgroundColor: Colors.amber[700],
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // 言葉グリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.6,
          ),
          itemCount: kCardDesignWords.length,
          itemBuilder: (context, index) {
            final word = kCardDesignWords[index];
            final isSelected = _selectedDesignWords.contains(word);
            final canSelect = !isSelected && _selectedDesignWords.length < 3;

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  setState(() => _selectedDesignWords.remove(word));
                } else if (canSelect) {
                  setState(() => _selectedDesignWords.add(word));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber[700] : (canSelect ? Colors.white : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (!canSelect ? Colors.grey[400] : Colors.black87),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttributeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('どの属性でカードを作成しますか？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('属性によって 3 すくみの相性が変わります', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        ...[
          ('joy', '☀️ 喜（Joy）', '怒に有利・哀に不利', const Color(0xFFFFD700), '太陽が輝く黄金の国'),
          ('anger', '🔥 怒（Anger）', '哀に有利・喜に不利', const Color(0xFFE74C3C), '火山と岩の大地'),
          ('sadness', '🌙 哀（Sadness）', '喜に有利・怒に不利', const Color(0xFF3498DB), '深い夜の森と静寂の湖'),
        ].map((item) {
          final isSelected = _attribute == item.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _attribute = item.$1),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? item.$4.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? item.$4 : Colors.grey[300]!, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Text(item.$2.split(' ')[0], style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2.split(' ')[1], style: TextStyle(fontWeight: FontWeight.bold, color: item.$4)),
                          Text(item.$3, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(item.$5, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: item.$4),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCostStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('カードのコストを選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('コストが高いほど強力なパラメータを配分できます', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        ...List.generate(5, (i) {
          final c = i + 1;
          final budget = switch (c) { 1 => 20, 2 => 25, 3 => 30, 4 => 35, _ => 40 };
          final isSelected = _cost == c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _cost = c;
                  _attack = 0;
                  _defense = 0;
                  _speed = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.amber[700]! : Colors.grey[300]!, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Text(List.generate(c, (_) => '★').join(), style: TextStyle(fontSize: 18, color: Colors.amber[600])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('コスト $c', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('パラメータ予算: $budget pt', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: Colors.amber[700]),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildParameterStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('パラメータを配分', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '予算: $_budget pt　残り: $_remaining pt',
          style: TextStyle(
            color: _remaining < 0 ? Colors.red : _remaining == 0 ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        _buildParamSlider('攻撃力', _attack, const Color(0xFFFF6347), (v) {
          if (_defense + _speed + v <= _budget) setState(() => _attack = v);
        }),
        const SizedBox(height: 16),
        _buildParamSlider('防御力', _defense, const Color(0xFF4169E1), (v) {
          if (_attack + _speed + v <= _budget) setState(() => _defense = v);
        }),
        const SizedBox(height: 16),
        _buildParamSlider('速度', _speed, const Color(0xFF9370DB), (v) {
          if (_attack + _defense + v <= _budget) setState(() => _speed = v);
        }),
        const SizedBox(height: 24),
        if (_attack > 0 || _defense > 0 || _speed > 0) ...[
          const Text('プレビュー', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 160,
              child: CardWidget(
                card: PlayCard(
                  cardId: 'preview',
                  attribute: _attribute ?? 'joy',
                  cost: _cost ?? 1,
                  attackPower: _attack,
                  defensePower: _defense,
                  speed: _speed,
                  nameJp: '（プレビュー）',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParamSlider(String label, int value, Color color, void Function(int) onChanged) {
    final max = _budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: max.toDouble(),
          divisions: max,
          activeColor: color,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildToneStep() {
    final tones = [
      ('cute', 'かわいい系', '親しみやすく、愛らしい'),
      ('cool', 'かっこいい系', '力強く、格好いい'),
      ('dark', '深刻系', '深く、内省的'),
      ('elegant', '優雅系', '上品で貴族的'),
      ('normal', '普通系', 'ニュートラル'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('カードのトーンを選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('AI がこのトーンでカード名を生成します', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        ...tones.map((t) {
          final isSelected = _tone == t.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _tone = t.$1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.amber[700]! : Colors.grey[300]!, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(t.$3, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: Colors.amber[700]),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNamingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('カード名を選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('AI が生成した 3 案からお選びください', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        if (_isGeneratingName) ...[
          const Center(child: CircularProgressIndicator(color: Colors.amber)),
          const SizedBox(height: 16),
          const Center(child: Text('カード名を生成中...', style: TextStyle(color: Colors.grey))),
        ] else ...[
          ..._nameCandidates.map((name) {
            final isSelected = _selectedName == name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedName = name),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.amber[700]! : Colors.grey[300]!, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (isSelected) Icon(Icons.check_circle, color: Colors.amber[700]),
                    ],
                  ),
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() => _isGeneratingName = true);
              _generateNames();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('別案を生成'),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '確定すると 🪙50 コイン が消費されます',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    switch (_step) {
      case 0:
        return ElevatedButton(
          onPressed: _selectedDesignWords.length == 3 ? () => setState(() => _step = 1) : null,
          child: const Text('次へ →'),
        );
      case 1:
        return ElevatedButton(
          onPressed: _attribute != null ? () => setState(() => _step = 2) : null,
          child: const Text('次へ →'),
        );
      case 2:
        return ElevatedButton(
          onPressed: _cost != null ? () => setState(() => _step = 3) : null,
          child: const Text('次へ →'),
        );
      case 3:
        return ElevatedButton(
          onPressed: _isParamValid ? () => setState(() => _step = 4) : null,
          child: const Text('次へ →'),
        );
      case 4:
        return ElevatedButton(
          onPressed: () {
            setState(() => _step = 5);
            _generateNames();
          },
          child: const Text('名前を生成 →'),
        );
      case 5:
        return ElevatedButton(
          onPressed: _selectedName != null ? _confirmAndPay : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
          child: const Text('🪙50 で作成'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _costToRarity(int cost) => switch (cost) {
        1 => 'n',
        2 => 'r',
        3 => 'r',
        4 => 'sr',
        _ => 'ur',
      };

  Future<void> _generateNames() async {
    try {
      final names = await FunctionsService.generateCardName(
        attribute: _attribute ?? 'joy',
        cost: _cost ?? 1,
        attack: _attack,
        defense: _defense,
        speed: _speed,
        tone: _tone,
      );
      if (!mounted) return;
      setState(() {
        _nameCandidates = names;
        _isGeneratingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      final fallback = ['光の${_tone == 'cute' ? '妖精' : 'アイコン'}', '${_attribute == 'joy' ? '太陽' : _attribute == 'anger' ? '炎' : '月'}の子', 'パワーカード'];
      setState(() {
        _nameCandidates = fallback;
        _isGeneratingName = false;
      });
    }
  }

  void _confirmAndPay() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('カード作成の確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('「$_selectedName」', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('🪙50 コインで作成しますか？'),
            const SizedBox(height: 4),
            const Text('（作成後はキャンセルできません）', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processPurchase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
            child: const Text('🪙50 で作成'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase() async {
    final result = await PurchaseService.purchaseCardCreation();
    if (!mounted) return;

    switch (result) {
      case PurchaseResult.success:
        _onCardCreated();
      case PurchaseResult.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('課金をキャンセルしました')),
        );
      case PurchaseResult.noProduct:
        _onCardCreated();
      case PurchaseResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('課金処理でエラーが発生しました'), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _onCardCreated() async {
    // 画像生成ローディング表示
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ImageGenLoadingDialog(
          attribute: _attribute ?? 'joy',
          rarity: _costToRarity(_cost ?? 1),
        ),
      );
    }

    String imageUrl = '';
    try {
      final card = PlayCard(
        cardId: 'tmp',
        attribute: _attribute ?? 'joy',
        cost: _cost ?? 1,
        attackPower: _attack,
        defensePower: _defense,
        speed: _speed,
        nameJp: _selectedName ?? 'カード',
      );
      imageUrl = await FunctionsService.generateCardImage(
        attribute: _attribute ?? 'joy',
        cardName: _selectedName ?? '',
        cardType: card.getCardType(),
        rarity: _costToRarity(_cost ?? 1),
        designWords: List<String>.from(_selectedDesignWords),
        tone: _tone,
      );
    } catch (e) {
      // 画像生成失敗時はプレースホルダーで続行
      imageUrl = '';
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    final newCard = PlayCard(
      cardId: 'created_${DateTime.now().millisecondsSinceEpoch}',
      attribute: _attribute ?? 'joy',
      cost: _cost ?? 1,
      attackPower: _attack,
      defensePower: _defense,
      speed: _speed,
      nameJp: _selectedName ?? 'カード',
      imageUrl: imageUrl,
    );

    if (!mounted) return;
    await CardRevealDialog.show(context, newCard);
    if (!mounted) return;

    // カード作成クエスト進捗更新
    final quests = ref.read(dailyQuestsProvider);
    final updated = quests.map((q) {
      if (q.type == QuestType.create && q.progress < q.target) {
        return q.copyWith(progress: q.progress + 1);
      }
      return q;
    }).toList();
    ref.read(dailyQuestsProvider.notifier).state = updated;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 「$_selectedName」をコレクションに追加！（🪙50 消費）'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 画像生成中ローディングダイアログ
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ImageGenLoadingDialog extends StatelessWidget {
  final String attribute;
  final String rarity;
  const _ImageGenLoadingDialog(
      {required this.attribute, required this.rarity});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (attribute) {
      'joy' => '☀️',
      'anger' => '🔥',
      _ => '🌙',
    };
    final color = switch (attribute) {
      'joy' => const Color(0xFFFFB300),
      'anger' => const Color(0xFFE53935),
      _ => const Color(0xFF1E88E5),
    };
    final rarityLabel = switch (rarity) {
      'ur' => '✨ UR — 伝説のカード',
      'sr' => '💎 SR — 壮大な情景',
      'r' => '🔵 R — 情景を描く',
      _ => '⚪ N — シンプルな背景',
    };
    return Dialog(
      backgroundColor: const Color(0xFF1C1530),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'カード画像を生成中...',
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              rarityLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 12),
            const Text(
              'AIがカードアートを描いています\n少しお待ちください（約20秒）',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
