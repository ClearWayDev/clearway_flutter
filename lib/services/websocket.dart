import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../providers/appInfo_state.dart';

class WebSocketService {
  late IO.Socket socket;

  void connect() {
    final container = ProviderContainer();
    final appInfo = container.read(appInfoProvider);
    socket = IO.io(appInfo!.backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
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
