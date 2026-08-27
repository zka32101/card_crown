import 'package:cloud_firestore/cloud_firestore.dart';

class DeckPreset {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> cardIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeckPreset({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.cardIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// プリセットの最終更新から経過時間（秒）を取得
  int get secondsSinceUpdate => DateTime.now().difference(updatedAt).inSeconds;

  /// copyWithメソッド：一部フィールドを更新した新しいインスタンスを作成
  DeckPreset copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? cardIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeckPreset(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestoreに保存するためのMapに変換
  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'cardIds': cardIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Firestoreのドキュメントスナップショットからインスタンスを作成
  factory DeckPreset.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String userId,
  }) {
    return DeckPreset(
      id: id,
      userId: userId,
      name: map['name'] ?? 'Unnamed Deck',
      description: map['description'] ?? '',
      cardIds: List<String>.from(map['cardIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
