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
      child: MaterialApp(
        title: 'Campus Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFC9B8FF),
            onPrimary: const Color(0xFF1C1A22),
            primaryContainer: const Color(0xFF3A2E6A),
            onPrimaryContainer: const Color(0xFFEDE0FF),
            secondary: const Color(0xFF94D4A4),
            tertiary: const Color(0xFFF2C469),
            error: const Color(0xFFF28E8A),
            surface: const Color(0xFF1C1A22),
            onSurface: const Color(0xFFEDE8F5),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0D13),
          fontFamily: 'Nunito',
          cardTheme: CardThemeData(
            color: const Color(0xFF1C1A22),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1C1A22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Color(0xFF7B7585)),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: Color(0xFFEDE8F5)),
            titleLarge: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: Color(0xFFEDE8F5)),
            bodyMedium:
                TextStyle(fontFamily: 'Nunito', color: Color(0xFFC4BDD1)),
          ),
        ),
        home: const AuthWrapper(),
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
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A22),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 15 / 255))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF3A2E6A),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,
                  color: const Color(0xFF7B7585)),
              selectedIcon: Icon(Icons.dashboard_rounded, color: cs.primary),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined,
                  color: const Color(0xFF7B7585)),
              selectedIcon: Icon(Icons.meeting_room_rounded, color: cs.primary),
              label: 'Salles',
            ),
          ],
        ),
      ),
    );
  }
}
