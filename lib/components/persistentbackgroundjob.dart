import 'dart:async';
import 'dart:ui';
import 'package:clearway/components/triggercall.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/websocket.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeBackgroundService() async {
  print("Initializing background service...");
  const notificationChannelId = 'my_foreground';
  const notificationId = 888;

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'ClearWay', // title
    description:
        'This channel is used for persistant notifications.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();

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

void startBackgroundConnection() {
  final websocket = WebSocketService.getInstance();
  final userInfo = ProviderContainer().read(userProvider);
  print("Starting background connection...");
  print("Websocket server URL: ${websocket.socket.io.uri}");
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

  if (userInfo!.userType == UserType.blind) {
    Geolocator.getPositionStream().listen((Position position) {
      websocket.socket.emit('location-report', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'UId': userInfo.uid,
      });
    });
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
