import 'package:flutter_test/flutter_test.dart';

import 'package:infofuel/main.dart';

void main() {
  testWidgets('App boots and shows the bottom navigation', (tester) async {
    await tester.pumpWidget(const InfofuelApp());
    await tester.pump();

    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
  });
}
