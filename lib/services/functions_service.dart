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

  // PvPバトル実行（サーバーサイド・改ざん防止のため結果はサーバーで再計算される）
  // カードの実数値・対戦相手デッキ・属性移住ボーナスは全てサーバー側の正本データから
  // 解決されるため、ここではcardIdとpvpMatchが発行したmatchIdのみを送る。
  static Future<Map<String, dynamic>> pvpBattle({
    required String matchId,
    required List<String> attackerDeckCardIds,
  }) async {
    final callable = _functions.httpsCallable(
      'pvpBattle',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call({
      'matchId': matchId,
      'attackerDeckCardIds': attackerDeckCardIds,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  // カードレンタル（サーバーサイド・借り手のコイン減算とクリエイターへの収益付与を
  // アトミックに行う。2ユーザー間の通貨移動のためクライアントの直接Firestore書き込みは
  // 許可していない）
  static Future<Map<String, dynamic>> rentCard({
    required String cardId,
    required String creatorId,
    required int rentalDays,
  }) async {
    final callable = _functions.httpsCallable('rentCard');
    final result = await callable.call({
      'cardId': cardId,
      'creatorId': creatorId,
      'rentalDays': rentalDays,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
