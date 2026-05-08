import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobready_app/services/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations uses the active locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: Builder(
          builder: (context) {
            return Text(AppLocalizations.of(context).t('Bonjour', 'Hello'));
          },
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
