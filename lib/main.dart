import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/classroom_list_screen.dart';
import 'services/classroom_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/timetable_service.dart';
import 'services/update_service.dart';
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
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => UpdateService()),
        Provider(create: (_) => TimetableService()),
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
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateSvc = context.read<UpdateService>();
    final hasUpdate = await updateSvc.checkForUpdate();
    if (hasUpdate && mounted) {
      _showUpdateDialog(context, updateSvc);
    }
  }

  void _showUpdateDialog(BuildContext context, UpdateService updateSvc) {
    final release = updateSvc.latestRelease!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Mise à jour disponible (${release.tagName})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Une nouvelle version de Classroom Tracker est disponible.'),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(release.body),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              updateSvc.downloadAndInstall();
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

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
