import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 現在のユーザーストリーム
final userStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 現在のユーザーID
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userStreamProvider).whenData((u) => u?.uid);
  return user.when(
    data: (uid) => uid,
    loading: () => null,
    error: (_, _) => null,
  );
});

// ユーザーが認証されているかどうか
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null;
});

// 匿名認証（初回ユーザー用）
Future<UserCredential> signInAnonymously() async {
  return await FirebaseAuth.instance.signInAnonymously();
}

// メール/パスワード認証
Future<UserCredential> signInWithEmail(String email, String password) async {
  return await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// ログアウト
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}
