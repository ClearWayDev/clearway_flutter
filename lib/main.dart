import 'package:clearway/components/dashboardscreen.dart';
import 'package:clearway/components/signinscreen.dart';
import 'package:clearway/components/signupscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './services/notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase/firebase_options.dart';

import './components/backendUrlWidget.dart';
import 'package:clearway/components/splashscreen.dart'; 
import 'package:clearway/components/welcomescreen.dart'; 
import 'package:clearway/providers/fcm_token_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearWay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) =>  WelcomeScreen(),
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignupFlowScreen(),
        '/dashboard': (context) =>  DashboardScreen(),
      },
      
    );
  }
}

// You can keep this MyHomePage if you want to display BackendUrlWidget as a separate page,
// or remove it if you want to handle that widget inside one of the screens.

class MyHomePage extends ConsumerStatefulWidget  {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeFCMToken();
  }

   Future<void> _initializeFCMToken() async {
    final token = await notificationService.getFCMToken();
    if (token != null) {
      ref.read(fcmTokenProvider.notifier).setToken(token);

    }

    // listen for token refresh
    notificationService.listenTokenRefresh((newToken) {
    ref.read(fcmTokenProvider.notifier).setToken(newToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const BackendUrlWidget(),
    );
  }
}
