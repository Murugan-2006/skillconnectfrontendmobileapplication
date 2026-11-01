import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/customer/worker_list_screen.dart';
import 'screens/customer/worker_details.dart';
import 'screens/customer/booking_screen.dart';
import 'screens/worker/dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/ai_service.dart';
import 'services/socket_service.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/customer/requesting_screen.dart';

import 'services/notification_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions for Android 13+ and iOS
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => AiService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const SkillConnectApp(),
    ),
  );
}

class SkillConnectApp extends StatelessWidget {
  const SkillConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        useMaterial3: true,
        fontFamily: 'Inter', // Default fonts will fallback beautifully
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/customer-home': (context) => const CustomerHomeScreen(),
        '/worker-dashboard': (context) => const WorkerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/worker-list': (context) => WorkerListScreen(category: ModalRoute.of(context)!.settings.arguments as String),
        '/worker-details': (context) => const WorkerDetailsScreen(),
        '/booking-screen': (context) => const BookingScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/requesting-screen': (context) => const RequestingScreen(),
      },
    );
  }
}
