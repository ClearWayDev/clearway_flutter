import 'dart:async';
import 'package:clearway/services/websocket.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class TriggerCall {
  static final websocket = WebSocketService.getInstance();

  static void handleIncomingCall(String myUId, String destUId) async {
    final completer = Completer<bool>();
    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: Uuid().v4(),
        nameCaller: 'Blind User',
        appName: 'ClearWay',
        avatar: 'https://i.ibb.co/pBs6Kht6/images.png',
        handle: 'A call from a blind user for help',
        type: 0,
        duration: 15000,
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: 'Missed call from a blind user',
          callbackText: '',
        ),
        extra: <String, dynamic>{'userId': '1a2b3c4d'},
        headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          logoUrl: 'assets/logo/app-logo.png',
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'assets/test.png',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
        ),
      ),
    );

    late StreamSubscription sub;
    sub = FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          _onCallAccepted(myUId, destUId);
          if (!completer.isCompleted) completer.complete(true);
          sub.cancel();
          break;
        case Event.actionCallDecline:
          _onCallDeclined(myUId, destUId);
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
          break;
        case Event.actionCallIncoming:
        case Event.actionCallStart:
        default:
          break;
      }
    });
  }

  static void _onCallAccepted(String myUId, String destUid) {
    websocket.socket.emit('call-accepted', {
      'myUId': myUId,
      'destUId': destUid,
    });
  }

  static void _onCallDeclined(String myUId, String destUid) {
    websocket.socket.emit('call-declined', {
      'myUId': myUId,
      'destUId': destUid,
    });
  }
}
