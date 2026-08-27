import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_models.dart';
import '../theme/kingdom_theme.dart';

class MarketplaceCurrencyScreen extends ConsumerWidget {
  const MarketplaceCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Kingdom.gilt,
            unselectedLabelColor: Kingdom.parchment.withValues(alpha: 0.6),
            indicatorColor: Kingdom.gilt,
            tabs: const [
              Tab(text: 'Buy Gems 💎'),
              Tab(text: 'Sell Gems 💎'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BuyGemsTab(),
                _SellGemsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyGemsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(currencyListingsByTypeProvider('sell_gems'));

    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No gem sellers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No players are currently selling gems',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort by best price (lowest coins per gem)
    final sorted = [...listings];
    sorted.sort((a, b) => a.price.compareTo(b.price));

    return ListView.builder(
      padding: const EdgeInsets.all(Kingdom.spaceMd),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final listing = sorted[index];
        return CurrencyListingTile(
          listing: listing,
          onFill: () => _showFillDialog(context, ref, listing, 'buy'),
        );
      },
    );
  }

  void _showFillDialog(BuildContext context, WidgetRef ref, CurrencyListing listing, String action) {
    final maxAmount = listing.amount;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy Gems'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: $maxAmount gems'),
            const SizedBox(height: 8),
            Text('Price: ${listing.price} 🪙 per gem'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Amount (1-$maxAmount)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            Builder(builder: (ctx) {
              int amount = int.tryParse(amountController.text) ?? 0;
              int total = amount * listing.price;
              return Text('Total: $total 🪙');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0 || amount > maxAmount) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount')),
                  );
                }
                return;
              }

              Navigator.pop(context);
              final success = await fillCurrencyListingFlow(ref, listing.listingId, amount: amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Purchase successful!' : 'Purchase failed'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }
}

class _SellGemsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(currencyListingsByTypeProvider('buy_gems'));

    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_down,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No gem buyers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No players are currently buying gems',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to create sell gems listing
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Sell Listing'),
            ),
          ],
        ),
      );
    }

    // Sort by best price (highest coins per gem)
    final sorted = [...listings];
    sorted.sort((a, b) => b.price.compareTo(a.price));

    return ListView(
      padding: const EdgeInsets.all(Kingdom.spaceMd),
      children: [
        ...sorted.map((listing) => CurrencyListingTile(
              listing: listing,
              onFill: () => _showFillDialog(context, ref, listing, 'sell'),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Kingdom.spaceMd),
          child: FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to create sell gems listing
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Sell Listing'),
          ),
        ),
      ],
    );
  }

  void _showFillDialog(BuildContext context, WidgetRef ref, CurrencyListing listing, String action) {
    final maxAmount = listing.amount;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'sell' ? 'Sell Gems' : 'Buy Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: $maxAmount ${action == 'sell' ? 'coins' : 'gems'}'),
            const SizedBox(height: 8),
            Text('Price: ${listing.price} ${action == 'sell' ? '🪙' : '💎'} per ${action == 'sell' ? 'gem' : 'coin'}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Amount (1-$maxAmount)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            Builder(builder: (ctx) {
              int amount = int.tryParse(amountController.text) ?? 0;
              int total = amount * listing.price;
              return Text('You receive: $total ${action == 'sell' ? '🪙' : '💎'}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0 || amount > maxAmount) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount')),
                  );
                }
                return;
              }

              Navigator.pop(context);
              final success = await fillCurrencyListingFlow(ref, listing.listingId, amount: amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Exchange successful!' : 'Exchange failed'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(action == 'sell' ? 'Sell' : 'Buy'),
          ),
        ],
      ),
    );
  }
}

class CurrencyListingTile extends StatelessWidget {
  final CurrencyListing listing;
  final VoidCallback onFill;

  const CurrencyListingTile({
    Key? key,
    required this.listing,
    required this.onFill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSellGems = listing.type == 'sell_gems';
    final currencyLabel = isSellGems ? '💎' : '💎';
    final coinsLabel = '🪙';

    return Card(
      color: Kingdom.nightDeep,
      margin: const EdgeInsets.only(bottom: Kingdom.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(Kingdom.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSellGems ? 'Buy Gems' : 'Buy Coins',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${listing.amount} ${isSellGems ? currencyLabel : coinsLabel} available',
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
                    Text(
                      isSellGems ? coinsLabel : currencyLabel,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Kingdom.spaceMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onFill,
                child: Text(isSellGems ? 'Buy Gems' : 'Sell Gems'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
