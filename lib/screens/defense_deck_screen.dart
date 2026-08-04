import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/game_state_provider.dart';
import 'deck_selection_screen_v2.dart';
import '../theme/kingdom_theme.dart';
import '../l10n/app_localizations.dart';

class DefenseDeckScreen extends ConsumerWidget {
  const DefenseDeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defenseDeck = ref.watch(defenseDeckProvider);
    final t = AppLocalizations.of(context)!;

    return DeckSelectionScreenV2(
      title: t.defenseDeck_setDeckTitle,
      initialDeck: defenseDeck,
      onConfirm: (deck) {
        ref.read(defenseDeckProvider.notifier).state = deck;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${t.defenseDeck_updateSuccess}'),
            backgroundColor: Kingdom.joyGold,
          ),
        );
        Navigator.pop(context);
      },
    );
  }
}
