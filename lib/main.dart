import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase_options.dart';
import 'package:ogs/services/landingservice/landingservice.dart';
import 'package:ogs/services/notifications_service.dart';
import 'package:ogs/services/points_service.dart';
import 'package:ogs/services/screen_time_tracker.dart';
import 'package:provider/provider.dart';
import 'form_response/form_response.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/events_view_all.dart';
import 'package:ogs/pages/ads_view_all.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/bus.dart';
import 'package:ogs/pages/s_points_page.dart';
import 'package:ogs/pages/s_vouchers.dart';
import 'package:ogs/pages/rateus.dart';
import 'dart:async';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  await OGSNotificationService.initialize();

  // Setup notification handling
  setupNotificationHandling();

  runApp(const MyApp());
}

void setupNotificationHandling() {
  OGSNotificationService.onNotificationTap = (type, data) {
    // Use the global navigator key to navigate
    final context = navigatorKey.currentContext;
    if (context != null) {
      Widget? page;

      switch (type) {
        case 'bus':
          page = const BusTrackPage();
          break;
        case 'event':
          page = const EventsViewAll();
          break;
        case 'movie':
          page = const MoviesPage();
          break;
        case 'hotel':
          page = const HotelPage();
          break;
        case 'restaurant':
          page = const RestaurantsPage();
          break;
        case 'offer':
          page = const AdsViewAll();
          break;
        case 'points':
          page = PointsScreen();
          break;
        case 'voucher':
          page = const VouchersScreen();
          break;
        default:
          return;
      }

      if (page != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => page!),
        );
      }
    }
  };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    // Delay rate dialog to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          RateUsManager.checkAndShowRateDialog(context);
        }
      });
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Listen to auth state changes
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          AuthServiceManager.onUserLogin(user.uid);
        } else {
          AuthServiceManager.onUserLogout();
        }
      });
    } catch (e) {
      print('Error initializing auth listener: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    AuthServiceManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FormResponse>(
      create: (context) => FormResponse(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Helvetica',
          primarySwatch: Colors.blue,
        ),
        home: AnimatedSplashScreen(
          splash: "lib/assets/icons/ani.gif",
          nextScreen: const Landing(),
          duration: 3000,
          backgroundColor: yel,
          centered: true,
          splashIconSize: 200,
        ),
      ),
    );
  }
}

// Centralized service manager to handle user authentication and services
class AuthServiceManager {
  static final ScreenTimeTracker _screenTimeTracker = ScreenTimeTracker();
  static String? _currentUserId;
  static bool _isInitialized = false;

  static Future<void> onUserLogin(String userId) async {
    try {
      // Prevent duplicate initialization for same user
      if (_currentUserId == userId && _isInitialized) {
        return;
      }

      // Dispose previous user's services if different user
      if (_currentUserId != null && _currentUserId != userId) {
        _dispose();
      }

      _currentUserId = userId;

      // Initialize services for user
      await _initializeUserServices(userId);
      _isInitialized = true;

      print('Services initialized for user: $userId');
    } catch (e) {
      print('Error in onUserLogin: $e');
    }
  }

  static Future<void> _initializeUserServices(String userId) async {
    try {
      // Initialize screen time tracking
      _screenTimeTracker.initialize(userId);

      // Initialize user points (uncomment when ready)
      // await PointsService.initializeUserPoints(userId);

      // Award daily login points
      await PointsService.awardDailyLoginPoints(userId);

      print('User services initialized successfully for user: $userId');
    } catch (e) {
      print('Error initializing user services: $e');
      rethrow;
    }
  }

  static void onUserLogout() {
    _dispose();
    _currentUserId = null;
    _isInitialized = false;
    print('User services disposed');
  }

  static void _dispose() {
    try {
      _screenTimeTracker.dispose();
    } catch (e) {
      print('Error disposing screen time tracker: $e');
    }
  }

  static void dispose() {
    _dispose();
  }

  // Getter for current user ID (useful for debugging)
  static String? get currentUserId => _currentUserId;
  static bool get isInitialized => _isInitialized;
}