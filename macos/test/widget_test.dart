import 'package:flutter_test/flutter_test.dart';
import 'package:smart_folder/main.dart';

void main() {
  testWidgets('SmartFolder startet erfolgreich', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFolderApp());

    expect(find.text('SmartFolder'), findsOneWidget);
  });
}
