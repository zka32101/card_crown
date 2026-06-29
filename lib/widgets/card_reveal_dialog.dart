import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_card.dart';
import '../services/sound_service.dart';
import 'card_widget.dart';

/// カード作成時のパック開封風リビール演出
/// タップで裏面 → 3Dフリップ → 表面（キラキラ輝き）
class CardRevealDialog extends StatefulWidget {
  final PlayCard card;

  const CardRevealDialog({super.key, required this.card});

  static Future<void> show(BuildContext context, PlayCard card) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CardRevealDialog(card: card),
    );
  }

  @override
  State<CardRevealDialog> createState() => _CardRevealDialogState();
}

class _CardRevealDialogState extends State<CardRevealDialog> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _shineController;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_revealed) return;
    setState(() => _revealed = true);
    playSound(SoundEffect.cardFlip);
    _flipController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFF34495E), Color(0xFF1A2530)],
            radius: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _revealed ? '✨ 新カード誕生！ ✨' : '🎴 タップして開封',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // フリップ演出
            GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: Listenable.merge([_flipController, _shineController]),
                builder: (context, child) {
                  final angle = _flipController.value * math.pi;
                  final isFront = angle > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isFront
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildFront(),
                          )
                        : _buildBack(),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            if (_revealed)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('コレクションに追加', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              )
            else
              const Text('カードパックをタップ！', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // カード裏面（パック）
  Widget _buildBack() {
    return Container(
      width: 170,
      height: 238,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
      ),
      child: const Center(child: Text('👑', style: TextStyle(fontSize: 64))),
    );
  }

  // カード表面（キラキラ輝きオーバーレイ付き）
  Widget _buildFront() {
    return Stack(
      children: [
        SizedBox(width: 170, child: CardWidget(card: widget.card, size: 170)),
        // 斜めに走るシャイン
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  final slide = _shineController.value * 2 - 0.5;
                  return LinearGradient(
                    begin: Alignment(slide - 0.3, -1),
                    end: Alignment(slide + 0.3, 1),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.35, 0.5, 0.65],
                  ).createShader(rect);
                },
                child: Container(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
