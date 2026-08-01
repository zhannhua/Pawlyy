import 'package:flutter_test/flutter_test.dart';
import 'package:pawlyy/main.dart';

void main() {
  testWidgets('shows secure setup instructions without Supabase credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const PawlyApp(isConfigured: false));

    expect(find.text('Connect Pawly to Supabase'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
