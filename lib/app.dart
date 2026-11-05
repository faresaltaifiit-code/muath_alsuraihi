import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _prayerNotifications = prayerNotificationsService;
  StreamSubscription<PrayerNotificationAction>? _notificationSubscription;
  PrayerNotificationAction? _pendingPrayerNotification;
  bool _isOpeningPrayerNotification = false;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = PrayerNotificationEvents.actions.listen(
      _queuePrayerNotification,
    );
    // Keep notification taps available even before the prayer screen is built.
    unawaited(_prayerNotifications.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestStartupPermissions());
    });
    final launchAction = PrayerNotificationEvents.takePendingAction();
    if (launchAction != null) _queuePrayerNotification(launchAction);
  }

  Future<void> _requestStartupPermissions() async {
    try {
      // iOS must finish one permission prompt before presenting another.
      final notificationsGranted = await _prayerNotifications.requestPermission();
      if (!mounted) return;
      final preferences = await SharedPreferences.getInstance();
      const askedKey = 'startup_location_permission_requested';
      final context = _navigatorKey.currentContext;
      if (!mounted || context == null) return;
      final prayers = context.read<PrayerTimesProvider>();
      while (mounted && !prayers.isLoaded) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;
      if (preferences.getBool(askedKey) != true) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied &&
            await Geolocator.isLocationServiceEnabled()) {
          await prayers.useCurrentLocation();
        }
        if (!mounted) return;
        if (permission != LocationPermission.denied ||
            await Geolocator.isLocationServiceEnabled()) {
          await preferences.setBool(askedKey, true);
        }
      }
      if (notificationsGranted) await prayers.enableAlertsIfNotConfigured();
    } catch (_) {
      // Leave the app usable and allow another attempt on a later launch.
    }
  }

  void _queuePrayerNotification(PrayerNotificationAction action) {
    _pendingPrayerNotification = action;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPendingPrayerNotification());
    });
  }

  Future<void> _openPendingPrayerNotification() async {
    if (_isOpeningPrayerNotification) return;
    _isOpeningPrayerNotification = true;
    try {
      // A notification can cold-launch the app before its navigator and player
      // provider exist. Retry for the first few frames instead of dropping the
      // tap; this makes "open notification → play full adhan" reliable.
      for (var attempt = 0; attempt < 12; attempt++) {
        final action = _pendingPrayerNotification;
        final navigator = _navigatorKey.currentState;
        final context = navigator?.context;
        if (!mounted || action == null) return;
        if (navigator != null && context != null) {
          _pendingPrayerNotification = null;
          await _handlePrayerNotification(action, navigator, context);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isOpeningPrayerNotification = false;
      if (_pendingPrayerNotification != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openPendingPrayerNotification());
        });
      }
    }
  }

  Future<void> _handlePrayerNotification(
    PrayerNotificationAction action,
    NavigatorState navigator,
    BuildContext context,
  ) async {
    final audio = switch (action) {
      PrayerNotificationAction.openAdhan => kAdhanAudio,
      PrayerNotificationAction.openIqama => kIqamaAudio,
    };
    final player = context.read<PlayerProvider>();
    // Show the destination before requesting playback. On a notification tap
    // iOS is still returning the app to the foreground; waiting briefly after
    // the route transition makes the audio session reliable on cold launches.
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerScreen(surah: audio),
        ),
      ).then<void>((_) {}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await player.initialize();
    if (action == PrayerNotificationAction.openAdhan) {
      await player.playAdhan();
    } else {
      await player.playIqama();
    }
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
