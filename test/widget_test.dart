import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:card_rivals/main.dart';

void main() {
  testWidgets('CardRivalsApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CardRivalsApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CardRivalsApp), findsOneWidget);
  });
}
