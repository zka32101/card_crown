import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/game_state_provider.dart';

enum QuestType { battle, create, win }

class DailyQuest {
  final QuestType type;
  final String title;
  final String icon;
  final int target;
  final int reward;
  final int progress;
  final bool claimed;

  const DailyQuest({
    required this.type,
    required this.title,
    required this.icon,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.claimed = false,
  });

  bool get completed => progress >= target;

  DailyQuest copyWith({int? progress, bool? claimed}) => DailyQuest(
        type: type,
        title: title,
        icon: icon,
        target: target,
        reward: reward,
        progress: progress ?? this.progress,
        claimed: claimed ?? this.claimed,
      );
}

final dailyQuestsProvider = StateProvider<List<DailyQuest>>((ref) => [
      const DailyQuest(type: QuestType.battle, title: 'バトルに参加', icon: '⚔️', target: 1, reward: 5),
      const DailyQuest(type: QuestType.create, title: 'カードを作成', icon: '🎴', target: 1, reward: 10),
      const DailyQuest(type: QuestType.win, title: '勝利する', icon: '🏆', target: 1, reward: 15),
    ]);

class DailyQuestsWidget extends ConsumerWidget {
  const DailyQuestsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(dailyQuestsProvider);
    final allDone = quests.every((q) => q.claimed);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[900]!, Colors.indigo[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋 デイリークエスト', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              if (allDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent)),
                  child: const Text('全完了!', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Text('${quests.where((q) => q.completed).length}/3', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...quests.asMap().entries.map((e) => _QuestRow(
                quest: e.value,
                index: e.key,
              )),
        ],
      ),
    );
  }
}

class _QuestRow extends ConsumerWidget {
  final DailyQuest quest;
  final int index;
  const _QuestRow({required this.quest, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = quest.completed;
    final isClaimed = quest.claimed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // アイコン
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isClaimed
                  ? Colors.green.withValues(alpha: 0.2)
                  : isDone
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isClaimed ? Colors.greenAccent : isDone ? Colors.amber : Colors.white24),
            ),
            child: Center(child: Text(isClaimed ? '✅' : quest.icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          // タイトル + プログレス
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: TextStyle(color: isClaimed ? Colors.white38 : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (quest.progress / quest.target).clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(isClaimed ? Colors.green : isDone ? Colors.amber : Colors.deepPurpleAccent),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 報酬 / クレームボタン
          if (isClaimed)
            Text('受取済', style: const TextStyle(color: Colors.white24, fontSize: 10))
          else if (isDone)
            GestureDetector(
              onTap: () {
                final quests = ref.read(dailyQuestsProvider);
                final updated = List<DailyQuest>.from(quests);
                updated[index] = quest.copyWith(claimed: true);
                ref.read(dailyQuestsProvider.notifier).state = updated;
                // コイン付与
                final w = ref.read(walletProvider);
                ref.read(walletProvider.notifier).state = w.copyWith(coinBalance: w.coinBalance + quest.reward);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🪙${quest.reward} 獲得!'), duration: const Duration(seconds: 2)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFAA00), Color(0xFFFFD700)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Text('🪙${quest.reward}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            )
          else
            Text('${quest.progress}/${quest.target}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
