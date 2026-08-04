import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_state_provider.dart';

// 移住コスト（コイン）
const int kMigrationCost = 50;
// 移住ボーナス倍率の上乗せ（属性有利/不利倍率に加算）
const double kMigrationBonusMultiplier = 0.15;

int _isoWeekNumber(DateTime date) {
  final dayOfYear = int.parse(
      (date.difference(DateTime(date.year, 1, 1)).inDays + 1).toString());
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

// 今週、優勢な属性（喜/怒/哀を週替わりでローテーション）
final weeklyFavoredAttributeProvider = Provider<String>((ref) {
  const attrs = ['joy', 'anger', 'sadness'];
  final week = _isoWeekNumber(DateTime.now());
  return attrs[week % 3];
});

class MigrationState {
  final String? attribute; // 現在移住済みの属性（null = 未移住）
  final int forWeek; // 何週目の移住か（週が変わったら無効）

  const MigrationState({this.attribute, this.forWeek = -1});
}

final migrationStateProvider = StateProvider<MigrationState>((ref) => const MigrationState());

// 有効な移住先（週が変わっていたら null 扱い）
final activeMigrationAttributeProvider = Provider<String?>((ref) {
  final state = ref.watch(migrationStateProvider);
  final currentWeek = _isoWeekNumber(DateTime.now());
  if (state.forWeek != currentWeek) return null;
  return state.attribute;
});

// 今週の優勢属性へ移住する（コイン消費）。残高不足なら false を返す。
bool migrateToFavoredAttribute(WidgetRef ref) {
  final wallet = ref.read(walletProvider);
  if (wallet.coinBalance < kMigrationCost) return false;

  final favored = ref.read(weeklyFavoredAttributeProvider);
  final currentWeek = _isoWeekNumber(DateTime.now());

  ref.read(walletProvider.notifier).state = wallet.copyWith(
    coinBalance: wallet.coinBalance - kMigrationCost,
  );
  ref.read(migrationStateProvider.notifier).state =
      MigrationState(attribute: favored, forWeek: currentWeek);
  return true;
}

String migrationAttributeEmoji(String attr) => switch (attr) {
      'joy' => '☀️',
      'anger' => '🔥',
      'sadness' => '🌙',
      _ => '⭐',
    };

String migrationAttributeLabel(String attr) => switch (attr) {
      'joy' => '喜の大陸',
      'anger' => '怒の大陸',
      'sadness' => '哀の大陸',
      _ => '?',
    };
