import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/classroom_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/classroom_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ClassroomTrackerApp());
}

class ClassroomTrackerApp extends StatelessWidget {
  const ClassroomTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProxyProvider<NotificationService, ClassroomService>(
          create: (_) => ClassroomService(),
          update: (_, notifSvc, classroomSvc) {
            classroomSvc!.updateNotificationService(notifSvc);
            return classroomSvc;
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeSvc, _) {
          return MaterialApp(
            title: 'Classroom Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: themeSvc.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeSvc.seedColor,
                brightness: Brightness.light,
              ),
              fontFamily: 'Nunito',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeSvc.seedColor,
                brightness: Brightness.dark,
              ),
              fontFamily: 'Nunito',
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isAuthenticated) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    ClassroomListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          indicatorColor: cs.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,
                  color: cs.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard_rounded, color: cs.onPrimaryContainer),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined,
                  color: cs.onSurfaceVariant),
              selectedIcon: Icon(Icons.meeting_room_rounded, color: cs.onPrimaryContainer),
              label: 'Salles',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined,
                  color: cs.onSurfaceVariant),
              selectedIcon: Icon(Icons.settings_rounded, color: cs.onPrimaryContainer),
              label: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }
}
