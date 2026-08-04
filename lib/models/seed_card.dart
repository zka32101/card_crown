class SeedCard {
  final String cardId;
  final String attribute; // "joy", "anger", "sadness"
  final int cost; // 1-5
  final int attackPower;
  final int defensePower;
  final int speed;
  final String nameJp;
  final String nameEn;
  final String descriptionJp;
  final String descriptionEn;
  // AI生成アート（アセットパス or URL）。未設定なら空文字でプレースホルダー表示になる。
  final String imageUrl;

  SeedCard({
    required this.cardId,
    required this.attribute,
    required this.cost,
    required this.attackPower,
    required this.defensePower,
    required this.speed,
    required this.nameJp,
    required this.nameEn,
    required this.descriptionJp,
    required this.descriptionEn,
    this.imageUrl = '',
  });

  String getCardType() {
    final params = [attackPower, defensePower, speed];
    final max = params.reduce((a, b) => a > b ? a : b);

    if (attackPower == max && attackPower > defensePower && attackPower > speed) {
      return 'attack';
    } else if (defensePower == max && defensePower > attackPower && defensePower > speed) {
      return 'defense';
    } else if (speed == max && speed > attackPower && speed > defensePower) {
      return 'speed';
    }
    return 'balance';
  }

  int getTotalStats() => attackPower + defensePower + speed;

  Map<String, dynamic> toMap() => {
    'cardId': cardId,
    'attribute': attribute,
    'cost': cost,
    'attackPower': attackPower,
    'defensePower': defensePower,
    'speed': speed,
    'nameJp': nameJp,
    'nameEn': nameEn,
    'descriptionJp': descriptionJp,
    'descriptionEn': descriptionEn,
    'imageUrl': imageUrl,
  };
}
