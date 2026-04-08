import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/cloudinary_service.dart';
import 'services/student_profile_service.dart';
import 'services/document_service.dart';
import 'services/notice_service.dart';
import 'services/academic_record_service.dart';
import 'services/scholarship_service.dart';
import 'services/application_service.dart';
import 'services/faculty_service.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'screens/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_dashboard.dart';

import 'screens/committee/committee_dashboard.dart';
import 'screens/faculty/faculty_dashboard.dart';
import 'utils/constants.dart';
import 'theme/premium_theme.dart';
import 'widgets/connectivity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase at the very beginning to prevent race conditions with MultiProvider
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase already initialized or error: $e');
  }

  // Lock to portrait mode to reduce layout recomputation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge system UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Configure image cache to cap GPU texture memory (Safe for 2GB RAM devices)
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  // Optimize Google Fonts: Prioritize local system fonts on network delay
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<CloudinaryService>(create: (_) => CloudinaryService()),
        Provider<StudentProfileService>(create: (_) => StudentProfileService()),
        Provider<DocumentService>(create: (_) => DocumentService()),
        Provider<NoticeService>(create: (_) => NoticeService()),
        Provider<AcademicRecordService>(create: (_) => AcademicRecordService()),
        Provider<ScholarshipService>(create: (_) => ScholarshipService()),
        Provider<ApplicationService>(create: (_) => ApplicationService()),
        Provider<FacultyService>(create: (_) => FacultyService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: AppInfo.appName,
        debugShowCheckedModeBanner: false,
        theme: PremiumTheme.lightTheme,
        darkTheme: PremiumTheme.darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) => ConnectivityWrapper(child: child!),
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/student': (context) => const StudentDashboard(),
          '/committee': (context) => const CommitteeDashboard(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {
  late Future<void> _initializationFuture;
  String _loadingStatus = 'Starting GDG App...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    debugPrint('Universal Optimization: Low memory detected, clearing caches...');
    // Clear image cache immediately on memory pressure (Crucial for low-end Android)
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<void> _initApp() async {
    if (mounted) setState(() => _loadingStatus = 'Connecting to Firebase...');
    
    // Firebase is already initialized in main(), but we wait a frame for stability
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) setState(() => _loadingStatus = 'Readying local storage...');
    await CacheService().init(); // Critical path (fast)

    // Fire-and-forget lazy loading of non-critical boxes
    CacheService().initRemainingBoxes();

    if (mounted) setState(() => _loadingStatus = 'Checking your session...');

    // Enable Firestore Persistence with bounded cache (100 MB)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100 MB bounded cache
    );
    debugPrint("Firebase & Cache initialized successfully");
  }

  void _retryInit() {
    setState(() {
      _initializationFuture = _initApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Initialization succeeded
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const AuthWrapper();
        }

        // Initialization failed - show error screen with retry
        if (snapshot.hasError) {
          return _ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: _retryInit,
          );
        }

        // Loading - branded splash screen
        return _SplashScreen(statusText: _loadingStatus);
      },
    );
  }
}

// ──────────────────────────────────────────────
// Branded Splash Screen (prevents plain black screen)
// ──────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  final String statusText;
  const _SplashScreen({this.statusText = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: PremiumTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: PremiumTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.school_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              AppInfo.appName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: PremiumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unified Student Welfare Portal',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: PremiumTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PremiumTheme.primary,
                ),
              ),
            ),
            if (statusText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Error Screen with Retry (prevents stuck black screen)
// ──────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The app could not initialize. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white30,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

// ──────────────────────────────────────────────
// Auth wrapper to handle role-based routing
// ──────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen(statusText: 'Checking authentication...');
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // --- PERFORMANCE OPTIMIZATION ---
        // 1. Instant Cached Role Check
        final cachedRole = authService.getCachedRole();
        if (cachedRole != null) {
          return _routeByRole(cachedRole);
        }

        // --- REACTIVE PROFILE SYNC ---
        // Using a stream ensures the UI automatically transitions 
        // as soon as the registration process is complete.
        return StreamBuilder<UserModel?>(
          stream: authService.userStream(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen(statusText: 'Synchronizing profile...');
            }

            final userData = userSnapshot.data;
            if (userData == null) {
              // --- REGISTRATION GRACE PERIOD ---
              // If the user was just created, wait for the profile.
              final isNewUser = user.metadata.creationTime != null &&
                  DateTime.now().toUtc().difference(user.metadata.creationTime!).inSeconds < 120;

              if (isNewUser) {
                debugPrint('AuthWrapper: New user detected (${user.uid}), waiting for profile creation...');
                return const _SplashScreen(statusText: 'Finalizing your profile...');
              }

              debugPrint('AuthWrapper: Profile sync failed for ${user.uid}. Kicking back to login.');
              authService.signOut();
              return const LoginScreen();
            }
            return _routeByRole(userData.role);
          },
        );
      },
    );
  }

  Widget _routeByRole(String role) {
    switch (role) {
      case 'committee':
        return const CommitteeDashboard();
      case 'faculty':
        return const FacultyDashboard();
      default:
        return const StudentDashboard();
    }
  }
}
