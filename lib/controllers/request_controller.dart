import 'dart:convert';
import 'package:speed_ios/model/my.requests.model.dart';
import 'package:speed_ios/model/received.sent.requests.model.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

class RequestsRepository {
  Future<MyRequestsModel> dispatchingRequest(
      int motorBikerId,
      int clientId,
      String requestType,
      DateTime requestedTime,
      String originLocation,
      String destinationLocation,
      String status) async {
    // Format the DateTime to 'yyyy-MM-ddTHH:mm:ss'
    String formattedDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(requestedTime);
    String now = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());

    // Build the request body
    var requestBody = {
      'motorBiker': {'id': motorBikerId},
      'client': {'id': clientId},
      'requestType': requestType,
      'requestedTime': formattedDate,
      'createdAt': now, // Set createdAt to the current date and time
      'updatedAt': now, // Set updatedAt to the current date and time
      'originLocation': originLocation,
      'destinationLocation': destinationLocation,
      'status': status
    };

    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      final url = Uri.parse('${dotenv.get('mainUrl')}/requests}');
      var response = await http.post(url,
          headers: headers, body: json.encode(requestBody));

      Map<String, dynamic> results = jsonDecode(response.body);

      if (response.statusCode == 200) {
        MyRequestsModel myRequestsModel = MyRequestsModel.fromJson(results);
        if (kDebugMode) {
          print("TEST 1 $results");
        }
        return myRequestsModel;
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        MyRequestsModel myRequestsModel = MyRequestsModel.fromJson(results);
        if (kDebugMode) {
          print("TEST 1 $results");
        }
        return myRequestsModel;
      } else {
        String message =
            'Something went wrong, please try again, or call support@speed.tz!';
        if (kDebugMode) {
          print("TEST 3 $message");
        }
        return MyRequestsModel(success: false, message: message, data: null);
      }
    } catch (e) {
      return MyRequestsModel(success: false, message: e.toString(), data: null);
    }
  }

  Future<UserSentRequestsModel> dispatchingFetchRequest(
    String clientId,
  ) async {
    try {
      var response = await http.get(
        Uri.parse('${dotenv.get('mainUrl')}/requests/client/$clientId'),
        headers: {
          "Content-type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> results = jsonDecode(response.body);
        UserSentRequestsModel userSentRequestsModel =
            UserSentRequestsModel.fromJson(results);

        return userSentRequestsModel;
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        Map<String, dynamic> results = jsonDecode(response.body);
        UserSentRequestsModel userSentRequestsModel =
            UserSentRequestsModel.fromJson(results);
        if (kDebugMode) {
          print("TEST 2 $results");
        }
        return userSentRequestsModel;
      } else {
        String message =
            'Something went wrong, please try again, or call support@speed.tz!';
        return UserSentRequestsModel(
            success: false, message: message, data: null);
      }
    } catch (e) {
      return UserSentRequestsModel(
          success: false, message: e.toString(), data: null);
    }
  }
}
