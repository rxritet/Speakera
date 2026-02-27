import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/duel/create_duel_screen.dart';
import 'presentation/screens/duel/duel_detail_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/leaderboard/leaderboard_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for persisted session on app launch.
    Future.microtask(
      () => ref.read(authProvider.notifier).checkSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and redirect accordingly.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is Authenticated) {
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
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
        '/create-duel': (_) => const CreateDuelScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/duel') {
          final duelId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => DuelDetailScreen(duelId: duelId),
          );
        }
        return null;
      },
    );
  }
}

/// Shell with bottom navigation: Duels / Leaderboard / Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Duels',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
