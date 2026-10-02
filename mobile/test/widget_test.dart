import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maintenance_app/main.dart';

void main() {
  testWidgets('La app arranca sin lanzar errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AplicacionMantenimiento()));
    await tester.pump();
  });
}
