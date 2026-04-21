import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/notifications/fcm_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/duel/create_duel_screen.dart';
import 'presentation/screens/duel/duel_detail_screen.dart';
import 'presentation/screens/duel/group_duel_lobby_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/leaderboard/leaderboard_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/xp_progress_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

/// Глобальный ключ навигатора — пробрасывается в FcmService для навигации из пушей.
final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const disableFirebaseWeb = bool.fromEnvironment(
    'DISABLE_FIREBASE_WEB',
    defaultValue: false,
  );

  try {
    if (!kIsWeb || !disableFirebaseWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // FCM инициализируем только на мобильных
    if (!kIsWeb) {
      FcmService.setNavigatorKey(_navigatorKey);
      await FcmService.instance.init();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await NotificationService.instance.init();
  await NotificationService.instance.restoreReminder();
  runApp(const ProviderScope(child: HabitDuelApp()));
}

class HabitDuelApp extends ConsumerStatefulWidget {
  const HabitDuelApp({super.key});

  @override
  ConsumerState<HabitDuelApp> createState() => _HabitDuelAppState();
}

class _HabitDuelAppState extends ConsumerState<HabitDuelApp> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkSession());
    Future.microtask(() => ref.read(themeModeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is Authenticated) {
        Future.microtask(() => FcmService.instance.syncCurrentUserToken());
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (_) => false,
        );
      } else if (next is Unauthenticated) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
        );
      }
    });

    return MaterialApp(
      title: 'HabitDuel',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
        '/create-duel': (_) => const CreateDuelScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/xp-progress': (_) => const XpProgressScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/duel') {
          final duelId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => DuelDetailScreen(duelId: duelId),
          );
        }
        if (settings.name == '/group-lobby') {
          final duelId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => GroupDuelLobbyScreen(duelId: duelId),
          );
        }
        return null;
      },
    );
  }
}

/// Shell с нижней навигацией: Duels / Leaderboard / Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget?> _screens = [const HomeScreen(), null, null];

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const LeaderboardScreen(),
      2 => const ProfileScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  void _selectTab(int index) {
    setState(() {
      _index = index;
      _screens[index] ??= _buildScreen(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.generate(
      _screens.length,
      (index) => _screens[index] ?? const SizedBox.shrink(),
    );

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: IndexedStack(index: _index, children: children),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Дуэли',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Рейтинг',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
