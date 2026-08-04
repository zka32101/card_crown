import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:card_crown/main.dart';

void main() {
  testWidgets('CardCrownApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CardCrownApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CardCrownApp), findsOneWidget);
  });
}
