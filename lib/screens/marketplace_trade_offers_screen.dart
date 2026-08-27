import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_models.dart';
import '../theme/kingdom_theme.dart';

class MarketplaceTradeOffersScreen extends ConsumerWidget {
  const MarketplaceTradeOffersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(myTradeOffersProvider);

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No trade offers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Send or receive trade offers with other players',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create trade offer screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Send Trade Offer'),
                ),
              ],
            ),
          );
        }

        final sentOffers = offers.where((o) => o.status == 'pending').toList();
        final receivedOffers = offers.where((o) => o.status == 'pending').toList();
        final completedOffers = offers.where((o) => ['accepted', 'rejected', 'expired', 'cancelled'].contains(o.status)).toList();

        return ListView(
          padding: const EdgeInsets.all(Kingdom.spaceMd),
          children: [
            // Pending Offers Section
            if (sentOffers.isNotEmpty || receivedOffers.isNotEmpty) ...[
              _SectionHeader('Pending Offers'),
              ...offers
                  .where((o) => o.status == 'pending')
                  .map((offer) => TradeOfferTile(offer: offer)),
              const SizedBox(height: Kingdom.spaceXxl),
            ],

            // Completed Trades Section
            if (completedOffers.isNotEmpty) ...[
              _SectionHeader('Completed (${completedOffers.length})'),
              ...completedOffers.map((offer) => CompletedTradeOfferTile(offer: offer)),
            ],

            // Create New Button
            if (offers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Kingdom.spaceMd),
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create trade offer screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Send Trade Offer'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class TradeOfferTile extends ConsumerWidget {
  final TradeOffer offer;

  const TradeOfferTile({Key? key, required this.offer}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncoming = offer.recipientId == ref.watch(currentUserIdProvider);

    return Card(
      color: Kingdom.nightDeep,
      margin: const EdgeInsets.only(bottom: Kingdom.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(Kingdom.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Trade Direction & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? 'Trade from ${offer.senderName}' : 'Trade to ${offer.recipientName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Kingdom.joyGold.withValues(alpha: 0.2),
                          border: Border.all(color: Kingdom.joyGold.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${offer.daysRemaining}d remaining',
                          style: TextStyle(fontSize: 11, color: Kingdom.joyGold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Kingdom.spaceMd),

            // Trade Cards Display
            Row(
              children: [
                // Sender Cards
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? 'Offering' : 'Sending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Kingdom.parchment.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...offer.senderCards.map((card) => _TradeCardChip(card: card)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceMd),
                  child: Icon(
                    Icons.compare_arrows,
                    color: Kingdom.joyGold,
                    size: 24,
                  ),
                ),
                // Recipient Cards
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isIncoming ? 'Asking for' : 'Receiving',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Kingdom.parchment.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      ...offer.recipientCards.map((card) => _TradeCardChip(card: card, align: TextAlign.right)),
                    ],
                  ),
                ),
              ],
            ),

            // Message (if present)
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: Kingdom.spaceMd),
              Container(
                padding: const EdgeInsets.all(Kingdom.spaceSm),
                decoration: BoxDecoration(
                  color: Kingdom.sadnessIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Kingdom.sadnessIndigo.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '"${offer.message}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Kingdom.parchment.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            // Action Buttons (for incoming offers)
            if (isIncoming && offer.status == 'pending') ...[
              const SizedBox(height: Kingdom.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectConfirm(context, ref, offer),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: Kingdom.spaceSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _showAcceptConfirm(context, ref, offer),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            // Action Buttons (for sent offers)
            if (!isIncoming && offer.status == 'pending') ...[
              const SizedBox(height: Kingdom.spaceMd),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel Offer'),
                  onPressed: () => _showCancelConfirm(context, ref, offer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAcceptConfirm(BuildContext context, WidgetRef ref, TradeOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Trade Offer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You will give ${offer.recipientCards.length} card(s)'),
            const SizedBox(height: 8),
            Text('You will receive ${offer.senderCards.length} card(s) from ${offer.senderName}'),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
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
              final success = await respondToTradeOfferFlow(ref, offer.offerId, 'accept');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Trade accepted!' : 'Failed to accept trade'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirm(BuildContext context, WidgetRef ref, TradeOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Trade Offer?'),
        content: Text('You are declining the trade offer from ${offer.senderName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await respondToTradeOfferFlow(ref, offer.offerId, 'reject');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Trade rejected' : 'Failed to reject trade'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirm(BuildContext context, WidgetRef ref, TradeOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trade Offer?'),
        content: Text('You are cancelling your trade offer to ${offer.recipientName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await cancelTradeOfferFlow(ref, offer.offerId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Trade offer cancelled' : 'Failed to cancel'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class CompletedTradeOfferTile extends StatelessWidget {
  final TradeOffer offer;

  const CompletedTradeOfferTile({Key? key, required this.offer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = offer.status == 'accepted' ? Colors.green : Colors.orange;
    final statusLabel = offer.status == 'accepted' ? 'Completed' : offer.status.capitalize();

    return Card(
      color: Kingdom.nightDeep.withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: Kingdom.spaceSm),
      child: Padding(
        padding: const EdgeInsets.all(Kingdom.spaceMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trade with ${offer.senderName == offer.senderId ? offer.recipientName : offer.senderName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Kingdom.parchment.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${offer.senderCards.length} ↔ ${offer.recipientCards.length} cards',
                    style: TextStyle(fontSize: 12, color: Kingdom.parchment.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeCardChip extends StatelessWidget {
  final TradeCard card;
  final TextAlign align;

  const _TradeCardChip({required this.card, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Kingdom.spaceSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Kingdom.spaceSm, vertical: 4),
        decoration: BoxDecoration(
          color: Kingdom.sadnessIndigo.withValues(alpha: 0.2),
          border: Border.all(color: Kingdom.sadnessIndigo.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${card.cardName['en'] ?? card.cardName['jp'] ?? 'Unknown'} (${card.cost})',
          style: TextStyle(
            fontSize: 11,
            color: Kingdom.parchment.withValues(alpha: 0.8),
          ),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Kingdom.spaceMd),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Kingdom.gilt,
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
