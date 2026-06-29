import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  // カード名生成（Claude Haiku）
  static Future<List<String>> generateCardName({
    required String attribute,
    required int cost,
    required int attack,
    required int defense,
    required int speed,
    required String tone,
  }) async {
    final callable = _functions.httpsCallable('generateCardName');
    final result = await callable.call({
      'attribute': attribute,
      'cost': cost,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'tone': tone,
    });
    final names = List<String>.from(result.data['names'] as List);
    return names;
  }

  // カード画像生成（Replicate Flux）
  // rarity: "n" | "r" | "sr" | "ur"
  // designWords: 3つのデザイン言葉
  // tone: "cute" | "cool" | "dark" | "elegant" | "normal"
  static Future<String> generateCardImage({
    required String attribute,
    required String cardName,
    required String cardType,
    required String rarity,
    required List<String> designWords,
    required String tone,
  }) async {
    final callable = _functions.httpsCallable(
      'generateCardImage',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call({
      'attribute': attribute,
      'cardName': cardName,
      'cardType': cardType,
      'rarity': rarity,
      'designWords': designWords,
      'tone': tone,
    });
    return result.data['imageUrl'] as String;
  }

  // PvPマッチング
  static Future<Map<String, dynamic>> pvpMatch(int attackerRating) async {
    final callable = _functions.httpsCallable('pvpMatch');
    final result = await callable.call({'attackerRating': attackerRating});
    return Map<String, dynamic>.from(result.data as Map);
  }

  // PvPバトル実行（サーバーサイド）
  static Future<Map<String, dynamic>> pvpBattle({
    required List<Map<String, dynamic>> attackerDeck,
    required List<Map<String, dynamic>> defenderDeckSnapshot,
    required String defenderUid,
  }) async {
    final callable = _functions.httpsCallable(
      'pvpBattle',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call({
      'attackerDeck': attackerDeck,
      'defenderDeckSnapshot': defenderDeckSnapshot,
      'defenderUid': defenderUid,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
