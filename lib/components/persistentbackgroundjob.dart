import 'dart:async';
import 'dart:ui';
import 'package:clearway/components/triggercall.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/services/authservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeBackgroundService() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure initialized synchronously

  final service = FlutterBackgroundService();
  // Ensure the service is not already running
  final isRunning = await service.isRunning();
  if (isRunning) {
    print("Background service is already running.");
    return;
  }
  print("nww Initializing background service...");
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
  WidgetsFlutterBinding.ensureInitialized(); // Ensure initialized synchronously

  // Do not request permissions here; ensure permissions are granted beforehand
  final socket = IO.io("https://api.clearway.live/", <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true,
  });
  print("Starting background connection...");
  print("Websocket server URL: ${socket.io.uri}");

  socket.emit('test-connection', {
    'message': 'Testing connection from background service',
    'timestamp': DateTime.now().toIso8601String(),
  });

  socket.onConnect((_) {
    print("WebSocket connected. Emitting location-report...");
    socket.emit('location-report', {'tst': "tst", 'stst': "tst", 'tst': "tst"});
  });

  socket.on('call-from-blind', (data) {
    TriggerCall.handleIncomingCall(
      data['myUId'] as String,
      data['destUId'] as String,
    );
  });

  AuthService authService = new AuthService();
  final userInfoFirebase = await authService.getCurrentUserData();
  print(userInfoFirebase);
  if (userInfoFirebase != null) {
    Geolocator.getCurrentPosition().then((Position position) {
      socket.emit('location-report', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'UId': userInfoFirebase.uid,
      });
    });

    Geolocator.getPositionStream().listen((Position position) {
      socket.emit('location-report', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'UId': userInfoFirebase.uid,
      });
    });
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure initialized synchronously

  // Do not request permissions here; ensure permissions are granted beforehand
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
