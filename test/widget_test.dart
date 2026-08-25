import 'package:flutter_test/flutter_test.dart';

import 'package:vocalearn/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VocaLearnApp());
    await tester.pumpAndSettle();

    expect(find.text('VocaLearn'), findsOneWidget);
  });
}
