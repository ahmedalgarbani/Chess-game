import 'package:chess_game/app/app.dart';
import 'package:chess_game/app/app_dependencies.dart';
import 'package:chess_game/features/home/presentation/home_page.dart';
import 'package:chess_game/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch shows onboarding in Arabic', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(RuqaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('أهلاً بك في رقعة'), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.byType(OnboardingPage)),
    );
    expect(direction, TextDirection.rtl);
  });

  testWidgets('onboarded players land on the home page', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.v1':
          '{"experience":"intermediate","playerName":"Ahmed","language":"en"}',
    });
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(RuqaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Hi, Ahmed'), findsOneWidget);
  });
}
