import 'dart:convert';

import '../model/cancel.request/cancel.request.model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CancelService {
  Future<CancelRequestModel> postCancelRequestInfo(
      String requestId, String feedback) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/cancel_ride_request'),
        headers: headers,
        body: json.encode({
          'requestId': requestId.toString(),
          'feedback': feedback.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      CancelRequestModel cancelRequestModel =
          CancelRequestModel.fromJson(results);
      return cancelRequestModel;
    } else if (response.statusCode == 400) {
      CancelRequestModel cancelRequestModel =
          CancelRequestModel.fromJson(results);
      return cancelRequestModel;
    } else {
      CancelRequestModel cancelRequestModel =
          CancelRequestModel.fromJson(results);
      return cancelRequestModel;
    }
  }
}
