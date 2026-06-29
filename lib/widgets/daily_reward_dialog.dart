import 'package:flutter/material.dart';

/// デイリーログインボーナス（7日間カレンダー＋連続ストリーク）
class DailyRewardDialog extends StatefulWidget {
  final int currentDay; // 1-7（本日が何日目か）
  final void Function(int coins) onClaim;

  const DailyRewardDialog({
    super.key,
    required this.currentDay,
    required this.onClaim,
  });

  /// 7日間の報酬テーブル
  static const rewards = [10, 15, 20, 30, 40, 60, 100];

  static Future<void> show(BuildContext context, {required int currentDay, required void Function(int) onClaim}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DailyRewardDialog(currentDay: currentDay, onClaim: onClaim),
    );
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = (widget.currentDay - 1).clamp(0, 6);
    final todayReward = DailyRewardDialog.rewards[todayIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4A6491)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁 デイリーボーナス', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${widget.currentDay}日連続ログイン中 🔥', style: const TextStyle(fontSize: 13, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 7日間カレンダー
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isToday = day == widget.currentDay;
                final isPast = day < widget.currentDay;
                final reward = DailyRewardDialog.rewards[i];
                final isBig = day == 7;

                return Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.amber[600]
                        : isPast
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday ? Colors.white : (isBig ? Colors.amberAccent : Colors.transparent),
                      width: isToday ? 2 : (isBig ? 1.5 : 0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Day$day', style: TextStyle(fontSize: 9, color: isToday ? Colors.white : Colors.white70)),
                      const SizedBox(height: 2),
                      Text(isBig ? '🎉' : '🪙', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('$reward', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? Colors.white : Colors.white70)),
                      if (isPast) const Icon(Icons.check_circle, size: 12, color: Colors.greenAccent),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 受取ボタン / 受取済み演出
            if (!_claimed)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _claimed = true);
                    _controller.forward();
                    widget.onClaim(todayReward);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('🪙$todayReward を受け取る', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            else
              ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                ),
                child: Column(
                  children: [
                    Text('+🪙$todayReward', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2C3E50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
