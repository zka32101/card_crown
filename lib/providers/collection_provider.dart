import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_card.dart';
import 'auth_provider.dart';
import 'game_state_provider.dart';

// ローカル状態管理用（既存のwalletProvider/migrationStateProviderと同じパターン）。
// カード作成直後にここへ楽観的に追加することで、Firestore書き込み完了を待たずに
// コレクション・デッキ編成画面へ即座に反映される。
final myCardsProvider = StateProvider<List<UserCard>>((ref) => []);

// walletHydratedForUidProviderと同じ役割のガード（ユーザーごとに1回だけ復元する）
final myCardsHydratedForUidProvider = StateProvider<String?>((ref) => null);

// Firestore統合版：ユーザーが作成した全カード
final userCardsFirestoreProvider = FutureProvider<List<UserCard>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cards')
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map((d) => UserCard.fromMap(d.data())).toList();
  } catch (e) {
    debugPrint('Error loading user cards: $e');
    return [];
  }
});

// シードカード + 自分が作成したカードを統合した、プレイヤーが実際に選べるカード一覧。
// デッキ編成・コレクション画面はこちらを使う（AI対戦相手の生成にはallPlayCardsProvider
// 〔シードカードのみ〕を引き続き使うこと — 相手デッキに自分のカードが混ざるのはおかしいため）。
final myCollectionProvider = Provider<List<PlayCard>>((ref) {
  final seedCards = ref.watch(allPlayCardsProvider);
  final myCards = ref.watch(myCardsProvider);
  return [...seedCards, ...myCards.map((c) => c.toPlayCard())];
});

Future<void> saveUserCard(String userId, UserCard card) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(card.cardId)
        .set(card.toMap(), SetOptions(merge: true));
  } catch (e) {
    debugPrint('Error saving user card: $e');
  }
}

// カードを1レベル特訓する（コイン消費）。上限到達・残高不足の場合はfalseを返す。
bool levelUpCard(WidgetRef ref, String cardId) {
  final cards = ref.read(myCardsProvider);
  final index = cards.indexWhere((c) => c.cardId == cardId);
  if (index == -1) return false;
  final card = cards[index];
  if (card.level >= kMaxCardLevel) return false;

  final cost = cardLevelUpCost(card.level);
  final wallet = ref.read(walletProvider);
  if (wallet.coinBalance < cost) return false;

  final updatedWallet = wallet.copyWith(coinBalance: wallet.coinBalance - cost);
  final updatedCard = card.copyWith(level: card.level + 1);

  ref.read(walletProvider.notifier).state = updatedWallet;
  final updatedCards = List<UserCard>.from(cards)..[index] = updatedCard;
  ref.read(myCardsProvider.notifier).state = updatedCards;

  final userId = ref.read(currentUserIdProvider);
  if (userId != null) {
    updateWallet(userId, updatedWallet);
    saveUserCard(userId, updatedCard);
  }
  return true;
}
