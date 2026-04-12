import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';

import 'screens/main_navigation_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase Initialized Successfully');
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  String? _initError;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
    debugPrint('MyApp: initState');
    Future.microtask(_initializeEverything);
  }

  Future<T> _withTimeout<T>(Future<T> f, Duration timeout, String name) async {
    try {
      return await f.timeout(timeout);
    } catch (e) {
      debugPrint('Initialization step "$name" failed or timed out: $e');
      rethrow;
    }
  }

  Future<void> _initializeEverything() async {
    try {
      // Limit each slow init to avoid indefinite blocking
      await _withTimeout(
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        const Duration(seconds: 10),
        'Firebase',
      );
      debugPrint('✓ Firebase initialized');

      // Enable Firestore offline persistence
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('✓ Firestore persistence enabled');
      } catch (e) {
        debugPrint('! Firestore persistence error: $e');
      }

      await _withTimeout(
        NotificationService.initialize(),
        const Duration(seconds: 8),
        'NotificationService',
      );
      debugPrint('✓ NotificationService initialized');

      // Additional async startup (AuthService, preloads) can run here with timeouts
      await _withTimeout(
        AuthService.instance.initialize(),
        const Duration(seconds: 8),
        'AuthService',
      );
      debugPrint('✓ AuthService initialized');

      setState(() {
        _initialized = true;
        _initError = null;
      });
    } catch (e, st) {
      debugPrint('Initialization error: $e\n$st');
      setState(() {
        _initialized = false;
        _initError = e.toString();
      });
      // Keep app running in safe mode even if init fails.
    }
  }

  Widget _buildErrorScreen(String message, VoidCallback onRetry) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized && _initError == null) {
      // Still initializing: show safe loading UI
      return ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'TaskCue',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
              ),
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: themeProvider.themeMode,
              home: const Scaffold(
                body: Center(
                  child: Text('Starting TaskCue... (Safe Mode)'),
                ),
              ),
            );
          },
        ),
      );
    }

    if (_initError != null) {
      // Init failed: show error UI but keep app responsive
      return ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'TaskCue',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
              ),
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: themeProvider.themeMode,
              home: _buildErrorScreen(
                'Startup error: $_initError',
                () {
                  if (mounted) {
                    setState(() {
                      _initError = null;
                    });
                    Future.microtask(_initializeEverything);
                  }
                },
              ),
            );
          },
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'TaskCue',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              textTheme: GoogleFonts.plusJakartaSansTextTheme(),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4F46E5),
                primary: const Color(0xFF4F46E5),
                secondary: const Color(0xFF10B981),
                surface: const Color(0xFFF8FAFC),
              ),
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                ),
                labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                primary: const Color(0xFF6366F1),
                secondary: const Color(0xFF10B981),
                surface: const Color(0xFF1E293B),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E293B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              initialData: FirebaseAuth.instance.currentUser,
              builder: (context, snapshot) {
                debugPrint(
                  'Auth Update: ${snapshot.connectionState}, Data: ${snapshot.data?.email}',
                );
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Starting TaskCue...'),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorScreen(
                    'Authentication error: ${snapshot.error}',
                    () {
                      if (mounted) {
                        setState(() {
                          _initialized = false;
                          _initError = null;
                        });
                        Future.microtask(_initializeEverything);
                      }
                    },
                  );
                }

                if (snapshot.data != null) {
                  return const MainNavigationScreen();
                }

                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}