import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/player_profile.dart';
import '../theme/kingdom_theme.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rankings'),
          backgroundColor: KingdomColors.primary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rating'),
              Tab(text: 'Wins'),
              Tab(text: 'Battles'),
              Tab(text: 'Win Rate'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRatingRanking(),
            _buildWinsRanking(),
            _buildBattlesRanking(),
            _buildWinRateRanking(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRanking() {
    return _buildRankingList(
      orderBy: 'currentRating',
      descending: true,
      title: 'Rating Ranking',
    );
  }

  Widget _buildWinsRanking() {
    return _buildRankingList(
      orderBy: 'totalWins',
      descending: true,
      title: 'Wins Ranking',
    );
  }

  Widget _buildBattlesRanking() {
    return _buildRankingList(
      orderBy: 'totalBattles',
      descending: true,
      title: 'Battles Ranking',
    );
  }

  Widget _buildWinRateRanking() {
    // 勝率ランキングは複雑なので、クライアント側で計算する
    return FutureBuilder<List<RankingEntry>>(
      future: _fetchAllPlayersAndSort(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final entries = snapshot.data ?? [];
        // 最小バトル数10以上のみを対象
        final filtered = entries.where((e) => e.totalBattles >= 10).toList();
        // 勝率でソート
        filtered.sort((a, b) => b.winRate.compareTo(a.winRate));

        return _buildRankingListView(filtered);
      },
    );
  }

  Widget _buildRankingList({
    required String orderBy,
    required bool descending,
    required String title,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collectionGroup('stats')
          .orderBy(orderBy, descending: descending)
          .limit(100)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final entries = <RankingEntry>[];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final entry = RankingEntry.fromFirestore(i + 1, data);
          entries.add(entry);
        }

        return _buildRankingListView(entries);
      },
    );
  }

  Widget _buildRankingListView(List<RankingEntry> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('No rankings available'));
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildRankingCard(context, entry);
      },
    );
  }

  Widget _buildRankingCard(BuildContext context, RankingEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [KingdomColors.primary, KingdomColors.accent],
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(entry.displayName),
        subtitle: Text('${entry.tier} • Rating: ${entry.rating}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalWins}W',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${entry.winRate.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => context.push('/profile/${entry.userId}'),
      ),
    );
  }

  Future<List<RankingEntry>> _fetchAllPlayersAndSort() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('stats')
          .limit(500)
          .get();

      final entries = <RankingEntry>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final data = snapshot.docs[i].data() as Map<String, dynamic>;
        final entry = RankingEntry.fromFirestore(i + 1, data);
        entries.add(entry);
      }

      return entries;
    } catch (e) {
      print('Error fetching players: $e');
      return [];
    }
  }
}
