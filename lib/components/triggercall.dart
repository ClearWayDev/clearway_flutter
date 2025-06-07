import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class TriggerCall {
  static void handleIncomingCall(String myUId, String destUId) async {
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

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallIncoming:
          // TODO: received an incoming call
          break;
        case Event.actionCallStart:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
          break;
        case Event.actionCallAccept:
          _onCallAccepted(myUId, destUId);
          break;
        case Event.actionCallDecline:
          _onCallDeclined(myUId, destUId);
          break;
        default:
      }
    });
  }

  static void _onCallAccepted(String myUId, String destUid) {
    print('Call accepted: ${destUid}');
    //TODO:  Add your logic for call acceptance here
  }

  static void _onCallDeclined(String myUId, String destUid) {
    print('Call declined: ${destUid}');
    //TODO:  Add your logic for call rejection here
  }
}
