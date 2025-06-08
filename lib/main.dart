import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './services/notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase/firebase_options.dart';

import './components/backendUrlWidget.dart';

import 'package:clearway/providers/fcm_token_state.dart';
import 'package:clearway/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ClearWay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

// You can keep this MyHomePage if you want to display BackendUrlWidget as a separate page,
// or remove it if you want to handle that widget inside one of the screens.

class MyHomePage extends ConsumerStatefulWidget {
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
