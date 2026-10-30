import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/game/domain/chess_ai_service.dart';
import '../features/home/presentation/home_page.dart';
import '../features/lan/domain/lan_service.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/progress/presentation/progress_cubit.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_cubit.dart';
import 'app_dependencies.dart';

class RuqaApp extends StatelessWidget {
  const RuqaApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChessAiService>.value(value: dependencies.aiService),
        RepositoryProvider<LanService>.value(value: dependencies.lanService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SettingsCubit(dependencies.settingsRepository),
          ),
          BlocProvider(
            create: (_) => ProgressCubit(dependencies.progressRepository),
          ),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (previous, current) =>
              previous.language != current.language,
          builder: (context, settings) {
            final onboarded = context
                .read<SettingsCubit>()
                .state
                .onboardingComplete;
            return MaterialApp(
              title: 'Ruqa Chess',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(),
              locale: Locale(settings.language.code),
              supportedLocales: [
                for (final language in AppLanguage.values)
                  Locale(language.code),
              ],
              localizationsDelegates: const [
                AppStringsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: onboarded ? const HomePage() : const OnboardingPage(),
            );
          },
        ),
      ),
    );
  }
}
