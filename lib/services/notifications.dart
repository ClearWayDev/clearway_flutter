import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';
import '../firebase/firebase_options.dart';

final _messageStreamController = BehaviorSubject<RemoteMessage>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Handling a foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
      print('Message notification: ${message.notification?.body}');

      _messageStreamController.sink.add(message);
    });

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<String?> getFCMToken() async {
    initialize();
    return await FirebaseMessaging.instance.getToken();
  }

  void listenTokenRefresh(Function(String) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      onRefresh(newToken);
    });
  }

  BehaviorSubject<RemoteMessage> get messageStream => _messageStreamController;

  void dispose() {
    _messageStreamController.close();
  }
}
