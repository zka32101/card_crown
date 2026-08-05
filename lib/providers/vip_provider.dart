import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/purchase_service.dart';

// VIPパスの有効状態（RevenueCatのEntitlementから取得）。
// 購入直後は vipStatusProvider.invalidate(ref) 相当（ref.invalidate(vipStatusProvider)）で
// 再取得すること。
final vipStatusProvider = FutureProvider<bool>((ref) => PurchaseService.isVipActive());
