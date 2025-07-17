import 'dart:async';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

import '../utils/SVConstants.dart';

class PostCall {
  final postUrl = 'https://fcm.googleapis.com/fcm/send';

  Future<bool> makeCall(String token, String title, String body) async {
    final data = {
      "notification": {"body": body, "title": title},
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": token
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization': 'key=${SVConstants.fcmServerKey}'
    };

    final response = await http.post(Uri.parse(postUrl),
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    if (response.statusCode == 200) {
      // on success do sth
      return true;
    } else {
      // on failure do sth
      return false;
    }
  }
}
