// Basic smoke test for DompetKu app shell
import 'package:flutter_test/flutter_test.dart';
import 'package:dompetku/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const DompetKuApp());
    await tester.pump();
    // App should render without errors
    expect(find.byType(DompetKuApp), findsOneWidget);
  });
}
