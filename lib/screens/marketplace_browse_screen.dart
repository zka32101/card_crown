import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_models.dart';
import '../theme/kingdom_theme.dart';

class MarketplaceBrowseScreen extends ConsumerWidget {
  const MarketplaceBrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeCardListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No listings yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new cards',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Kingdom.spaceMd),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return CardListingTile(
              listing: listing,
              onBuy: () => _showBuyConfirmDialog(context, ref, listing),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showBuyConfirmDialog(BuildContext context, WidgetRef ref, CardListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card: ${listing.cardName['en'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Price: ${listing.price} 🪙'),
            const SizedBox(height: 8),
            Text(
              'Platform Fee: ${listing.platformFee} 🪙 (10%)',
              style: const TextStyle(fontSize: 12, color: Colors.amber),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${listing.price} 🪙',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              _performBuy(context, ref, listing);
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _performBuy(BuildContext context, WidgetRef ref, CardListing listing) async {
    final success = await buyCardFlow(ref, listing.listingId);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Card purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to purchase card'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CardListingTile extends StatelessWidget {
  final CardListing listing;
  final VoidCallback? onBuy;

  const CardListingTile({
    Key? key,
    required this.listing,
    this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardNameDisplay = listing.cardName['en'] ?? listing.cardName['jp'] ?? 'Unknown Card';

    return Card(
      color: Kingdom.nightDeep,
      margin: const EdgeInsets.only(bottom: Kingdom.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(Kingdom.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Card Name & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardNameDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${listing.sellerName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Kingdom.parchment.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${listing.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Kingdom.gilt,
                      ),
                    ),
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Kingdom.spaceSm),

            // Card Stats
            Row(
              children: [
                _StatChip('Cost ${listing.cost}', Kingdom.sadnessIndigo),
                const SizedBox(width: Kingdom.spaceXs),
                _StatChip(listing.attribute, Kingdom.joyGold),
                const SizedBox(width: Kingdom.spaceXs),
                Expanded(
                  child: Text(
                    '${listing.views} views',
                    style: TextStyle(
                      fontSize: 12,
                      color: Kingdom.parchment.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Kingdom.spaceMd),

            // Buy Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBuy,
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceSm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
