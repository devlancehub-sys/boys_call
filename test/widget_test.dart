import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:love_call_boys/app/love_call_boys_app.dart';

void main() {
  testWidgets('LoveCallBoysApp builds MaterialApp shell', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Love Call')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(LoveCallBoysApp(router: router));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Love Call'), findsOneWidget);
  });
}
