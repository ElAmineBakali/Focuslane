import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mi_dashboard_personal/core/notifications/notifications_facade.dart';
import 'package:mi_dashboard_personal/design/theme/theme.dart';
import 'package:mi_dashboard_personal/design/theme/prefs.dart';
import 'package:mi_dashboard_personal/screens/food/services/food_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'design/widgets/app_background.dart';
import 'navigation/app_route_observer.dart';
import 'navigation/app_routes.dart';
import 'navigation/app_router.dart';
import 'core/services/core_sync_service.dart';
import 'core/services/ai_backend_client.dart';
import 'app/app_bootstrap.dart';
import 'package:mi_dashboard_personal/screens/study/services/study_firestore_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
const double kFabAvoidHeight = 84.0;
const String _coreSyncCustomToken = String.fromEnvironment(
  'CORE_SYNC_CUSTOM_TOKEN',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrapApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemePreset _preset = ThemePreset.ocean;
  ThemeMode _themeMode = ThemeMode.system;
  BackgroundStyle _bgStyle = BackgroundStyle.none;
  bool _loaded = false;

  FoodFirestoreService? _foodSvc;
  GymFirestoreService? _gymService;
  StudyFirestoreService? _studySvc;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && _coreSyncCustomToken.trim().isNotEmpty) {
      unawaited(
        fb_auth.FirebaseAuth.instance
            .signInWithCustomToken(_coreSyncCustomToken.trim())
            .then((cred) {
              debugPrint('[CoreSync][debugAuth] signed uid=${cred.user?.uid}');
              final uid = cred.user?.uid;
              if (uid != null && uid.isNotEmpty) {
                CoreSyncService.I.stop();
                CoreSyncService.I.start(uid);
              }
            })
            .catchError((e) {
              debugPrint('[CoreSync][debugAuth] signInWithCustomToken failed: $e');
            }),
      );
    }
    if (kDebugMode && AiBackendClient.isDevEnv) {
      unawaited(AiBackendClient().debugPing());
    }
    _loadPrefs();
    _askNotifPermission();
    NotificationsFacade.I.attachNavigatorKey(appNavigatorKey);
  }

  @override
  void dispose() {
    CoreSyncService.I.dispose();
    super.dispose();
  }

  Future<void> _askNotifPermission() async {
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();
      await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Notifications] permission request skipped: $e');
      }
    }
  }

  Future<void> _loadPrefs() async {
    final (p, m, b) = await ThemePrefs.load();
    setState(() {
      _preset = p;
      _themeMode = m;
      _bgStyle = b;
      _loaded = true;
    });
  }

  void toggleTheme(bool isDarkMode) {
    final next = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    setState(() => _themeMode = next);
    ThemePrefs.save(preset: _preset, mode: next, bg: _bgStyle);
  }

  ThemeData _safe(ThemeData candidate) {
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _safe(AppTheme.getLight(_preset)),
        darkTheme: _safe(AppTheme.getDark(_preset)),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
        ),
        navigatorObservers: [appRouteObserver],
      );
    }

    final light = _safe(AppTheme.getLight(_preset));
    final dark = _safe(AppTheme.getDark(_preset));

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Mi Dashboard Personal',
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      navigatorObservers: [appRouteObserver],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final padded = mq.copyWith(
          padding: mq.padding + const EdgeInsets.only(bottom: kFabAvoidHeight),
        );
        return MediaQuery(
          data: padded,
          child: AppBackground(
            style: _bgStyle,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: AppRoutes.home,
      routes: buildAppRoutes(
        AppRouterDependencies(
          preset: _preset,
          themeMode: _themeMode,
          backgroundStyle: _bgStyle,
          onChangePreset: (p) {
            setState(() => _preset = p);
            ThemePrefs.save(preset: _preset, mode: _themeMode, bg: _bgStyle);
          },
          onChangeMode: (m) {
            setState(() => _themeMode = m);
            ThemePrefs.save(preset: _preset, mode: _themeMode, bg: _bgStyle);
          },
          onChangeBackground: (b) {
            setState(() => _bgStyle = b);
            ThemePrefs.save(preset: _preset, mode: _themeMode, bg: _bgStyle);
          },
          foodService: () {
            final userId =
                fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
            _foodSvc ??= FoodFirestoreService(userId);
            return _foodSvc!;
          },
          gymService: () {
            _gymService ??= GymFirestoreService();
            return _gymService!;
          },
          studyService: () {
            _studySvc ??= StudyFirestoreService();
            return _studySvc!;
          },
        ),
      ),
      onGenerateRoute: (settings) => null,
    );
  }
}

