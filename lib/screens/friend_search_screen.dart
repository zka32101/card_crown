import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:card_rivals/providers/friends_provider.dart';
import 'package:card_rivals/models/player_public_profile.dart';
import 'friend_detail_screen.dart';

class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendSearchScreen> createState() =>
      _FriendSearchScreenState();
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    return userId.when(
      data: (id) => _buildSearchUI(id),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSearchUI(String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search players by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: _searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search for players',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type a player name to find friends',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _buildSearchResults(userId),
        ),
      ],
    );
  }

  Widget _buildSearchResults(String userId) {
    final searchAsync = ref.watch(searchPlayersProvider(_searchQuery));

    return searchAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No players found matching "$_searchQuery"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final profile = results[index];
            return SearchResultTile(
              profile: profile,
              userId: userId,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FriendDetailScreen(
                      friendId: profile.playerId,
                      friendName: profile.displayName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
    );
  }
}

/// Tile for displaying a search result
class SearchResultTile extends ConsumerWidget {
  final CompactPlayerProfile profile;
  final String userId;
  final VoidCallback? onTap;

  const SearchResultTile({
    Key? key,
    required this.profile,
    required this.userId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFriendAsync = ref.watch(isFriendProvider(profile.playerId));
    final hasRequestAsync =
        ref.watch(hasFriendRequestProvider(profile.playerId));

    return isFriendAsync.when(
      data: (isFriend) => hasRequestAsync.when(
        data: (hasRequest) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
            ),
          ),
          title: Text(profile.displayName),
          subtitle: Row(
            children: [
              Chip(
                label: Text(
                  'Tier ${profile.tier}',
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Text(
                'Rating: ${profile.rating.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Text(
                'Win Rate: ${profile.winRate.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: isFriend
              ? const Chip(label: Text('Friends'))
              : hasRequest
                  ? const Chip(label: Text('Pending'))
                  : ElevatedButton(
                      onPressed: () => _sendFriendRequest(context, ref),
                      child: const Text('Add'),
                    ),
          onTap: onTap,
        ),
        loading: () => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(profile.displayName.isNotEmpty
                ? profile.displayName[0].toUpperCase()
                : '?'),
          ),
          title: Text(profile.displayName),
          subtitle: Text('Rating: ${profile.rating.toStringAsFixed(0)}'),
          trailing: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, stack) => ListTile(
          title: Text(profile.displayName),
          trailing: ElevatedButton(
            onPressed: () => _sendFriendRequest(context, ref),
            child: const Text('Add'),
          ),
        ),
      ),
      loading: () => ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(profile.displayName.isNotEmpty
              ? profile.displayName[0].toUpperCase()
              : '?'),
        ),
        title: Text(profile.displayName),
        subtitle: Text('Rating: ${profile.rating.toStringAsFixed(0)}'),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => ListTile(
        title: Text(profile.displayName),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(context, ref),
          child: const Text('Add'),
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context, WidgetRef ref) async {
    final userDataAsync = ref.watch(playerPublicProfileProvider(userId));

    await userDataAsync.when(
      data: (userData) async {
        try {
          await sendFriendRequest(
            senderId: userId,
            senderName: userData.displayName,
            senderRating: userData.rating,
            recipientId: profile.playerId,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Friend request sent!'),
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Invalidate relevant providers
          ref.invalidate(hasFriendRequestProvider(profile.playerId));
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading user data...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (err, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $err'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
