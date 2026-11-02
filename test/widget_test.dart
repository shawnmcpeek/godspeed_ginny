import 'package:flutter_test/flutter_test.dart';
import 'package:godspeed_ginny/main.dart';

void main() {
  testWidgets('App boots into shell', (tester) async {
    await tester.pumpWidget(const GodspeedGinnyApp());
    await tester.pump();
    expect(find.byType(GodspeedGinnyApp), findsOneWidget);
  });
}
