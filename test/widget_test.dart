import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:metall_estimate/main.dart';
import 'package:metall_estimate/providers/project_provider.dart';
import 'package:metall_estimate/providers/notes_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => NotesProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
