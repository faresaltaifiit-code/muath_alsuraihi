import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/adhan_content.dart';
import 'core/services/prayer_notifications_service.dart';
import 'core/theme/app_theme.dart';
import 'features/player/presentation/player_screen.dart';
import 'features/navigation/presentation/root_navigation_screen.dart';
import 'features/welcome/presentation/welcome_screen.dart';
import 'providers/recitations_provider.dart';
import 'providers/player_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/prayer_times_provider.dart';

class MuathAlsuraihiApp extends StatefulWidget {
  const MuathAlsuraihiApp({super.key});

  @override
  State<MuathAlsuraihiApp> createState() => _MuathAlsuraihiAppState();
}

class _MuathAlsuraihiAppState extends State<MuathAlsuraihiApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _prayerNotifications = PrayerNotificationsService();
  StreamSubscription<PrayerNotificationAction>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = PrayerNotificationEvents.actions.listen(
      _handlePrayerNotification,
    );
    // Keep notification taps available even before the prayer screen is built.
    unawaited(_prayerNotifications.initialize());
  }

  Future<void> _handlePrayerNotification(PrayerNotificationAction action) async {
    // The notification can launch a cold app, so wait until Navigator exists.
    await Future<void>.delayed(Duration.zero);
    final navigator = _navigatorKey.currentState;
    final context = navigator?.context;
    if (navigator == null || context == null) return;
    final audio = switch (action) {
      PrayerNotificationAction.openAdhan => kAdhanAudio,
      PrayerNotificationAction.openIqama => kIqamaAudio,
    };
    final player = context.read<PlayerProvider>();
    if (action == PrayerNotificationAction.openAdhan) {
      await player.playAdhan();
    } else {
      await player.playIqama();
    }
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(surah: audio),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => RecitationsProvider()..loadSurahs()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(
            notificationsService: _prayerNotifications,
          )..load(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: _navigatorKey,
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
