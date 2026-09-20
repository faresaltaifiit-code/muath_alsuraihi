import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/root_navigation_screen.dart';
import 'features/welcome/presentation/welcome_screen.dart';
import 'providers/recitations_provider.dart';
import 'providers/player_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/settings_provider.dart';

class MuathAlsuraihiApp extends StatelessWidget {
  const MuathAlsuraihiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecitationsProvider()..loadSurahs()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: !settings.isLoaded
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : settings.hasSeenWelcome
                  ? const RootNavigationScreen()
                  : const WelcomeScreen(),
        ),
      ),
    );
  }
}

