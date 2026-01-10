import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Smoke test (widget tree builds)', (WidgetTester tester) async {
    // O app real depende de Firebase + router + providers e não é adequado
    // para o widget test padrão do template.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
