import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_dashboard_personal/supabase_config.dart';
import 'package:mi_dashboard_personal/models/outfit_model.dart';
import 'package:mi_dashboard_personal/screens/culture/culture_routes.dart';
import 'package:mi_dashboard_personal/screens/goals/goals_home_screen.dart';
import 'package:mi_dashboard_personal/screens/modules_screen.dart';
import 'package:mi_dashboard_personal/screens/notes/note_model.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_builder_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_detail_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/outfit_list_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/planificador_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/prenda_form_screen.dart';
import 'package:mi_dashboard_personal/screens/ropa/ropa_home_screen.dart';
import 'package:mi_dashboard_personal/screens/skills/skills_routes.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_edit_screen.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_model.dart';
import 'package:mi_dashboard_personal/screens/trading/live/trading_live_chart_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'package:mi_dashboard_personal/widgets/avoid_fab.dart';
import 'package:mi_dashboard_personal/widgets/auth_gate.dart';
import 'package:mi_dashboard_personal/screens/auth/login_screen.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'theme/prefs.dart';
import 'widgets/app_background.dart';
import 'screens/home_screen.dart';
import 'screens/tasks/tasks_main_screen.dart';
import 'screens/tasks/task_create_screen.dart';
import 'screens/notes/notes_list_screen.dart';
import 'screens/notes/note_editor_screen.dart';
import 'screens/habits/habits_table_screen.dart';
import 'screens/habits/habit_create_screen.dart';
import 'screens/habits/habit_detail_screen.dart';
import 'screens/habits/habit_stats_screen.dart';
import 'screens/habits/habit_model.dart';
import 'screens/gym/main/gym_main_screen.dart';
import 'screens/gym/services/gym_firestore_service.dart';
import 'screens/gym/routines/routines_list_screen.dart';
import 'screens/gym/analytics/gym_analytics_screen_v2.dart';
import 'screens/gym/goals/gym_goals_screen.dart';
import 'screens/gym/body/bodyweight_screen.dart';
import 'screens/gym/body/measurements_screen.dart';
import 'screens/study/services/study_firestore_service.dart';
import 'screens/study/timer/study_timer_screen.dart';
import 'screens/study/analytics/study_analytics_screen.dart';
import 'screens/study/main/study_main_screen.dart';
import 'screens/food/services/food_firestore_service.dart';
import 'screens/food/main/food_main_screen.dart';
import 'screens/finance/finance_routes.dart';
import 'screens/meditation/meditation_routes.dart';
import 'screens/trading/trading_routes.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'navigation/app_route_observer.dart';
import 'navigation/app_routes.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService.I.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    final n = msg.notification;
    if (n != null) {
      await NotificationService.I.showNow(
        id: (n.title ?? 'msg').hashCode ^ (n.body ?? '').hashCode,
        title: n.title ?? 'Mensaje',
        body: n.body ?? '',
      );
    }
  });
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Configure Firebase Auth persistence
  try {
    if (kIsWeb) {
      await fb_auth.FirebaseAuth.instance.setPersistence(
        fb_auth.Persistence.LOCAL,
      );
    }
  } catch (_) {}

  // Configure Firestore persistence
  try {
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      await FirebaseFirestore.instance.enablePersistence();
      FirebaseFirestore.instance.settings = const Settings(
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (_) {}

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

  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _askNotifPermission();
    NotificationService.I.scheduleHabitDailyReminder(
      const TimeOfDay(hour: 0, minute: 0),
    );

    _notifSub = NotificationService.I.onPayload.listen((p) {
      if (p == 'OPEN_HABITS') {
        appNavigatorKey.currentState?.pushNamed('/habits');
      } else if (p == 'OPEN_CALENDAR') {
        appNavigatorKey.currentState?.pushNamed('/calendar');
      } else if (p == 'OPEN_TASKS') {
        appNavigatorKey.currentState?.pushNamed('/tasks');
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _askNotifPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.getToken();
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
    final seed = candidate.colorScheme.primary;
    final bright = candidate.brightness;
    final fixed = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: bright),
      textTheme: candidate.textTheme,
    );
    return fixed.copyWith(
      appBarTheme: candidate.appBarTheme,
      cardTheme: candidate.cardTheme,
      chipTheme: candidate.chipTheme,
      elevatedButtonTheme: candidate.elevatedButtonTheme,
      inputDecorationTheme: candidate.inputDecorationTheme,
      iconTheme: candidate.iconTheme,
    );
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
              padding:
                  mq.padding + const EdgeInsets.only(bottom: kFabAvoidHeight),
            );
            return MediaQuery(
              data: padded,
              child: AppBackground(
                style: _bgStyle,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },

          home: AuthGate(
            authenticated: HomeScreen(
              toggleTheme: (isDark) {
                setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
                ThemePrefs.save(
                  preset: _preset,
                  mode: _themeMode,
                  bg: _bgStyle,
                );
              },
              themeMode: _themeMode,
            ),
            unauthenticated: const LoginScreen(),
          ),

          routes: {
            '/settings':
                (_) => SettingsScreen(
                  currentPreset: _preset,
                  currentMode: _themeMode,
                  currentBackground: _bgStyle,
                  onChangePreset: (p) {
                    setState(() => _preset = p);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                  onChangeMode: (m) {
                    setState(() => _themeMode = m);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                  onChangeBackground: (b) {
                    setState(() => _bgStyle = b);
                    ThemePrefs.save(
                      preset: _preset,
                      mode: _themeMode,
                      bg: _bgStyle,
                    );
                  },
                ),
            '/modules': (_) => const ModulesScreen(),
            '/tasks': (_) => const TasksMainScreen(),
            '/tasks/create': (_) => const TaskCreateScreen(),
            '/tasks/detail': (ctx) {
              final task = ModalRoute.of(ctx)!.settings.arguments as Task;
              return TaskEditScreen(task: task);
            },

            '/notes': (_) => const NotesListScreen(),
            '/notes/list': (_) => const NotesListScreen(),
            '/notes/editor': (ctx) {
              final args = ModalRoute.of(ctx)!.settings.arguments;
              if (args is Note) {
                return NoteEditorScreen(note: args);
              } else if (args is String) {
                return NoteEditorScreen(noteId: args);
              } else {
                return const NoteEditorScreen();
              }
            },

            '/habits': (_) => const HabitsTableScreen(),
            '/habits/create': (_) => const HabitCreateScreen(),
            '/habit-create': (_) => const HabitCreateScreen(),
            '/habits/detail': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitDetailScreen(habit: habit);
            },
            '/habit-detail': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitDetailScreen(habit: habit);
            },
            '/habits/stats': (ctx) {
              final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
              return HabitStatsScreen(habit: habit);
            },

            AppRoutes.gymDashboard: (_) {
              _gymService ??= GymFirestoreService();
              return GymMainScreen(svc: _gymService!);
            },
            '/gym/routines': (_) {
              _gymService ??= GymFirestoreService();
              return RoutinesListScreen(svc: _gymService!);
            },
            '/gym/analytics': (_) {
              _gymService ??= GymFirestoreService();
              return GymAnalyticsScreenV2(svc: _gymService!);
            },
            '/gym/goals': (_) {
              _gymService ??= GymFirestoreService();
              return GymGoalsScreen(svc: _gymService!);
            },
            '/gym/body/weight': (_) {
              _gymService ??= GymFirestoreService();
              return BodyweightScreen(svc: _gymService!);
            },
            '/gym/body/measurements': (_) {
              _gymService ??= GymFirestoreService();
              return MeasurementsScreen(svc: _gymService!);
            },

            AppRoutes.studyDashboard: (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyMainScreen(svc: _studySvc!);
            },
            '/study/timer': (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyTimerScreen(svc: _studySvc!);
            },
            '/study/analytics': (_) {
              _studySvc ??= StudyFirestoreService();
              return StudyAnalyticsScreen(svc: _studySvc!);
            },

            AppRoutes.foodDashboard: (_) {
              final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
              _foodSvc ??= FoodFirestoreService(userId);
              return FoodMainScreen(svc: _foodSvc!);
            },

            ...financeRoutes,
            ...meditationRoutes,
            ...tradingRoutes,
            ...cultureRoutes,
            ...skillsRoutes,

            '/calendar': (_) => const CalendarScreen(),
            '/ropa': (_) => const RopaHomeScreen(),
            '/prendaForm': (_) => const PrendaFormScreen(),
            '/outfitBuilder': (_) => const OutfitBuilderScreen(),
            '/outfits': (_) => const OutfitListScreen(),
            '/outfitDetalle': (ctx) {
              final outfit = ModalRoute.of(ctx)!.settings.arguments as Outfit;
              return OutfitDetailScreen(outfit: outfit);
            },
            '/planificadorRopa': (_) => const PlanificadorScreen(),
            '/trading/live': (_) => const TradingLiveChartScreen(),
            GoalsHomeScreen.route: (_) => const GoalsHomeScreen(),
          },
          onGenerateRoute: (settings) => null,
        );
  }
}
