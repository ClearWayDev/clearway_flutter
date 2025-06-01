import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../providers/appInfo_state.dart';
import '../providers/user_state.dart';

class WebSocketService {
  late IO.Socket socket =
      socket = IO.io("http://localhost", <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });
  final container = ProviderContainer();

  WebSocketService() {
    initService();
  }

  void initService() {
    final appInfo = container.read(appInfoProvider);
    final userInfo = container.read(userProvider);

    container.listen(appInfoProvider, (previous, next) {
      print("AppInfo changed: $next");
      if (next != previous) {
        disconnect();
        initService();
      }
    });

    socket = IO.io(appInfo!.backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.emit('init', {
      'uid': userInfo!.uid,
      'userType': userInfo.accountType.toString().split('.').last,
      'fcmToken': "dfdfdf",
    });

    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    socket.on('event', (data) {
      print('Received event: $data');
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });
  }

  void sendMessage(String event, dynamic data) {
    socket.emit(event, data);
  }

  void disconnect() {
    socket.disconnect();
  }
}
