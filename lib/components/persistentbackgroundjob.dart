import 'dart:async';
import 'dart:ui';
import 'package:clearway/components/triggercall.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/authservice.dart';
import 'package:clearway/services/websocket.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  // Ensure the service is not already running
  final isRunning = await service.isRunning();
  if (isRunning) {
    print("Background service is already running.");
    return;
  }
  print("Initializing background service...");
  const notificationChannelId = 'my_foreground';
  const notificationId = 888;

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'ClearWay', // title
    description:
        'This channel is used for persistent notifications.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Request notification permissions
  if (await Permission.notification.isDenied ||
      await Permission.notification.isPermanentlyDenied) {
    print("Requesting notification permissions...");
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print(
        "Notification permissions denied. Background service cannot proceed.",
      );
      return;
    }
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),

    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: notificationChannelId,
      initialNotificationContent: "ClearWay app is running",
      initialNotificationTitle: "ClearWay",
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [
        AndroidForegroundType.location,
        AndroidForegroundType.dataSync,
      ],
    ),
  );

  // Ensure the service starts after configuration
  service.startService();
}

Future<void> startBackgroundConnection() async {
  final websocket = WebSocketService.getInstance();
  final userInfo = ProviderContainer().read(userProvider);
  print("Starting background connection...");
  print("Websocket server URL: ${websocket.socket.io.uri}");

  // Check and request location permissions
  if (await Permission.location.isDenied ||
      await Permission.location.isPermanentlyDenied) {
    print("Requesting location permissions...");
    final status = await Permission.location.request();
    if (!status.isGranted) {
      print(
        "Location permissions denied. Background connection cannot proceed.",
      );
      return;
    }
  }

  Connectivity().onConnectivityChanged.listen((results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile)) {
      websocket.socket.connect();
    } else if (results.contains(ConnectivityResult.none)) {
      websocket.disconnect();
    }
  });

  websocket.socket.on('call-from-blind', (data) {
    TriggerCall.handleIncomingCall(
      data['myUId'] as String,
      data['destUId'] as String,
    );
  });

  AuthService authService = new AuthService();
  final userInfoFirebase = await authService.getCurrentUserData();

  if (await Permission.location.isDenied ||
      await Permission.location.isPermanentlyDenied) {
    print("Requesting location permissions...");
    final status = await Permission.location.request();
  } else {
    if (userInfoFirebase != null) {
      Geolocator.getCurrentPosition().then((Position position) {
        websocket.socket.emit('location-report', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'UId': userInfoFirebase.uid,
        });
      });
      Geolocator.getPositionStream().listen((Position position) {
        websocket.socket.emit('location-report', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'UId': userInfoFirebase.uid,
        });
      });
    }
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("Background service started"); // Add print statement for debugging
  startBackgroundConnection();

  service.on("stop").listen((event) {
    service.stopSelf();
    print("background process is now stopped");
  });

  service.on("start").listen((event) {
    print(
      "background process is now started",
    ); // Add print statement for debugging
  });
}
