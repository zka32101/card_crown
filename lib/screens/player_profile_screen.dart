import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/player_profile.dart';
import '../providers/player_stats_provider.dart';
import '../theme/kingdom_theme.dart';

class PlayerProfileScreen extends ConsumerWidget {
  final String? userId; // nullの場合は自分のプロフィール

  const PlayerProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileFuture = userId != null
        ? ref.watch(playerProfileProvider(userId!).future)
        : ref.watch(myProfileProvider.future);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        backgroundColor: KingdomColors.primary,
      ),
      body: profileFuture.when(
        data: (profile) => _buildProfile(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, PlayerProfile profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ヘッダー（ユーザー情報）
          _buildHeader(context, profile),
          const Divider(),
          // タブセクション
          _buildStatsSection(profile),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerProfile profile) {
    return Container(
      color: KingdomColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // プレイヤー名 + ティア
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [KingdomColors.primary, KingdomColors.accent],
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildTierBadge(profile.tier),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // レーティング情報
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Rating', '${profile.stats.currentRating}'),
              _buildStatBox('Battles', '${profile.stats.totalBattles}'),
              _buildStatBox('Wins', '${profile.stats.totalWins}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader2(BuildContext context, PlayerProfile profile) {
    return Container(
      color: KingdomColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // プレイヤー名 + ティア
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [KingdomColors.primary, KingdomColors.accent],
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildTierBadge(profile.tier),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // レーティング情報
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Rating', '${profile.stats.currentRating}'),
              _buildStatBox('Battles', '${profile.stats.totalBattles}'),
              _buildStatBox('Wins', '${profile.stats.totalWins}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    final colors = {
      'Bronze': Colors.brown,
      'Silver': Colors.grey,
      'Gold': Colors.amber,
      'Platinum': Colors.cyan,
      'Diamond': Colors.purple,
      'Master': Colors.red,
      'Grandmaster': Colors.deepPurple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors[tier] ?? Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: KingdomColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(PlayerProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Win Rate', '${profile.stats.winRate.toStringAsFixed(1)}%'),
          _buildStatRow('Max Win Streak', '${profile.stats.maxWinStreak}'),
          _buildStatRow('Max Loss Streak', '${profile.stats.maxLossStreak}'),
          _buildStatRow('Current Streak', profile.stats.winStreak > 0 ? '+${profile.stats.winStreak}' : '-${profile.stats.lossStreak}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
