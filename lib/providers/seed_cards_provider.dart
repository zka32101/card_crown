import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/seed_cards_data.dart';
import '../models/seed_card.dart';

final seedCardsProvider = Provider<List<SeedCard>>((ref) {
  return seedCardsData;
});

final seedCardsByAttributeProvider = Provider.family<List<SeedCard>, String>((ref, attribute) {
  return ref.watch(seedCardsProvider).where((card) => card.attribute == attribute).toList();
});

final seedCardsByCostProvider = Provider.family<List<SeedCard>, int>((ref, cost) {
  return ref.watch(seedCardsProvider).where((card) => card.cost == cost).toList();
});
