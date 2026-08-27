import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date format: $value');
}

/// Represents a card listing for sale in the marketplace
class CardListing {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String cardId;
  final String attribute;
  final int cost;
  final Map<String, String> cardName;
  final String imageUrl;
  final int price;
  final String status; // active, sold, delisted
  final DateTime createdAt;
  final DateTime? soldAt;
  final String? buyerId;
  final String? buyerName;
  final DateTime? expiresAt;
  final int views;

  const CardListing({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.cardId,
    required this.attribute,
    required this.cost,
    required this.cardName,
    required this.imageUrl,
    required this.price,
    required this.status,
    required this.createdAt,
    this.soldAt,
    this.buyerId,
    this.buyerName,
    this.expiresAt,
    this.views = 0,
  });

  /// Price per cost ratio (useful for comparing cards of different rarities)
  double get pricePerCost => price / cost;

  /// Check if listing has expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Platform fee for this listing (10% of sale price)
  int get platformFee => (price * 10 / 100).round();

  /// Amount seller will receive after fee
  int get sellerReceives => price - platformFee;

  /// Create a copy with modified fields
  CardListing copyWith({
    String? listingId,
    String? sellerId,
    String? sellerName,
    String? cardId,
    String? attribute,
    int? cost,
    Map<String, String>? cardName,
    String? imageUrl,
    int? price,
    String? status,
    DateTime? createdAt,
    DateTime? soldAt,
    String? buyerId,
    String? buyerName,
    DateTime? expiresAt,
    int? views,
  }) {
    return CardListing(
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      cardId: cardId ?? this.cardId,
      attribute: attribute ?? this.attribute,
      cost: cost ?? this.cost,
      cardName: cardName ?? this.cardName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      expiresAt: expiresAt ?? this.expiresAt,
      views: views ?? this.views,
    );
  }

  factory CardListing.fromMap(Map<String, dynamic> map) {
    return CardListing(
      listingId: map['listingId'] as String,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String,
      cardId: map['cardId'] as String,
      attribute: map['attribute'] as String,
      cost: map['cost'] as int,
      cardName: Map<String, String>.from(map['cardName'] as Map? ?? {}),
      imageUrl: map['imageUrl'] as String? ?? '',
      price: map['price'] as int,
      status: map['status'] as String? ?? 'active',
      createdAt: _parseDateTime(map['createdAt']),
      soldAt: map['soldAt'] != null ? _parseDateTime(map['soldAt']) : null,
      buyerId: map['buyerId'] as String?,
      buyerName: map['buyerName'] as String?,
      expiresAt: map['expiresAt'] != null ? _parseDateTime(map['expiresAt']) : null,
      views: map['views'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'cardId': cardId,
    'attribute': attribute,
    'cost': cost,
    'cardName': cardName,
    'imageUrl': imageUrl,
    'price': price,
    'status': status,
    'createdAt': createdAt,
    'soldAt': soldAt,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'expiresAt': expiresAt,
    'views': views,
  };

  @override
  String toString() => 'CardListing($listingId: $cardName by $sellerName)';
}

/// Represents a direct trade offer between two players
class TradeOffer {
  final String offerId;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final List<String> senderCardIds;
  final List<String> recipientCardIds;
  final String status; // pending, accepted, rejected, expired, cancelled
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final String? message;
  final List<TradeCard> senderCards;
  final List<TradeCard> recipientCards;

  const TradeOffer({
    required this.offerId,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.senderCardIds,
    required this.recipientCardIds,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    this.message,
    this.senderCards = const [],
    this.recipientCards = const [],
  });

  /// Check if trade has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get days remaining until expiry
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// Create a copy with modified fields
  TradeOffer copyWith({
    String? offerId,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    List<String>? senderCardIds,
    List<String>? recipientCardIds,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    String? message,
    List<TradeCard>? senderCards,
    List<TradeCard>? recipientCards,
  }) {
    return TradeOffer(
      offerId: offerId ?? this.offerId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      senderCardIds: senderCardIds ?? this.senderCardIds,
      recipientCardIds: recipientCardIds ?? this.recipientCardIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      message: message ?? this.message,
      senderCards: senderCards ?? this.senderCards,
      recipientCards: recipientCards ?? this.recipientCards,
    );
  }

  factory TradeOffer.fromMap(Map<String, dynamic> map) {
    return TradeOffer(
      offerId: map['offerId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      recipientId: map['recipientId'] as String,
      recipientName: map['recipientName'] as String,
      senderCardIds: List<String>.from(map['senderCardIds'] as List? ?? []),
      recipientCardIds: List<String>.from(map['recipientCardIds'] as List? ?? []),
      status: map['status'] as String? ?? 'pending',
      createdAt: _parseDateTime(map['createdAt']),
      respondedAt: map['respondedAt'] != null ? _parseDateTime(map['respondedAt']) : null,
      expiresAt: _parseDateTime(map['expiresAt']),
      message: map['message'] as String?,
      senderCards: (map['senderCards'] as List?)?.map((c) => TradeCard.fromMap(c as Map<String, dynamic>)).toList() ?? [],
      recipientCards: (map['recipientCards'] as List?)?.map((c) => TradeCard.fromMap(c as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'offerId': offerId,
    'senderId': senderId,
    'senderName': senderName,
    'recipientId': recipientId,
    'recipientName': recipientName,
    'senderCardIds': senderCardIds,
    'recipientCardIds': recipientCardIds,
    'status': status,
    'createdAt': createdAt,
    'respondedAt': respondedAt,
    'expiresAt': expiresAt,
    'message': message,
    'senderCards': senderCards.map((c) => c.toMap()).toList(),
    'recipientCards': recipientCards.map((c) => c.toMap()).toList(),
  };

  @override
  String toString() => 'TradeOffer($offerId: $senderId → $recipientId)';
}

/// Cached card data in trade offers
class TradeCard {
  final String cardId;
  final String attribute;
  final int cost;
  final Map<String, String> cardName;
  final String imageUrl;

  const TradeCard({
    required this.cardId,
    required this.attribute,
    required this.cost,
    required this.cardName,
    required this.imageUrl,
  });

  factory TradeCard.fromMap(Map<String, dynamic> map) {
    return TradeCard(
      cardId: map['cardId'] as String,
      attribute: map['attribute'] as String,
      cost: map['cost'] as int,
      cardName: Map<String, String>.from(map['cardName'] as Map? ?? {}),
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'cardId': cardId,
    'attribute': attribute,
    'cost': cost,
    'cardName': cardName,
    'imageUrl': imageUrl,
  };
}

/// Represents a gem-to-coin currency listing
class CurrencyListing {
  final String listingId;
  final String playerId;
  final String type; // sell_gems, buy_gems
  final int amount;
  final int price;
  final String status; // active, filled, cancelled
  final DateTime createdAt;
  final DateTime? filledAt;
  final DateTime expiresAt;

  const CurrencyListing({
    required this.listingId,
    required this.playerId,
    required this.type,
    required this.amount,
    required this.price,
    required this.status,
    required this.createdAt,
    this.filledAt,
    required this.expiresAt,
  });

  /// Total coins for sell_gems or gems for buy_gems
  int get totalValue => amount * price;

  /// Check if listing has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CurrencyListing.fromMap(Map<String, dynamic> map) {
    return CurrencyListing(
      listingId: map['listingId'] as String,
      playerId: map['playerId'] as String,
      type: map['type'] as String,
      amount: map['amount'] as int,
      price: map['price'] as int,
      status: map['status'] as String? ?? 'active',
      createdAt: _parseDateTime(map['createdAt']),
      filledAt: map['filledAt'] != null ? _parseDateTime(map['filledAt']) : null,
      expiresAt: _parseDateTime(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'playerId': playerId,
    'type': type,
    'amount': amount,
    'price': price,
    'status': status,
    'createdAt': createdAt,
    'filledAt': filledAt,
    'expiresAt': expiresAt,
  };
}

/// Record of a marketplace transaction
class MarketplaceTransaction {
  final String transactionId;
  final String type; // card_sale, trade_accepted, currency_exchange
  final String playerId;
  final int coinsDelta;
  final int gemsDelta;
  final int transactionFeeCoins;
  final String relatedListingId;
  final String? counterpartyId;
  final String? counterpartyName;
  final DateTime createdAt;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const MarketplaceTransaction({
    required this.transactionId,
    required this.type,
    required this.playerId,
    required this.coinsDelta,
    this.gemsDelta = 0,
    this.transactionFeeCoins = 0,
    required this.relatedListingId,
    this.counterpartyId,
    this.counterpartyName,
    required this.createdAt,
    this.isSuccessful = true,
    this.errorMessage,
    this.metadata = const {},
  });

  factory MarketplaceTransaction.fromMap(Map<String, dynamic> map) {
    return MarketplaceTransaction(
      transactionId: map['transactionId'] as String,
      type: map['type'] as String,
      playerId: map['playerId'] as String,
      coinsDelta: map['coinsDelta'] as int,
      gemsDelta: map['gemsDelta'] as int? ?? 0,
      transactionFeeCoins: map['transactionFeeCoins'] as int? ?? 0,
      relatedListingId: map['relatedListingId'] as String,
      counterpartyId: map['counterpartyId'] as String?,
      counterpartyName: map['counterpartyName'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      isSuccessful: map['isSuccessful'] as bool? ?? true,
      errorMessage: map['errorMessage'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() => {
    'transactionId': transactionId,
    'type': type,
    'playerId': playerId,
    'coinsDelta': coinsDelta,
    'gemsDelta': gemsDelta,
    'transactionFeeCoins': transactionFeeCoins,
    'relatedListingId': relatedListingId,
    'counterpartyId': counterpartyId,
    'counterpartyName': counterpartyName,
    'createdAt': createdAt,
    'isSuccessful': isSuccessful,
    'errorMessage': errorMessage,
    'metadata': metadata,
  };

  @override
  String toString() => 'MarketplaceTransaction($transactionId: $type for $playerId)';
}
