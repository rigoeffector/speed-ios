import 'dart:convert';
import 'package:speed_ios/model/my.requests.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../model/received.sent.requests.model.dart';

class RequestsRepository {
  final http.Client? httpClient;
  static const String _defaultErrorMessage =
      'Something went wrong, please try again, or call support@speed.tz!';

  RequestsRepository({http.Client? client})
      : httpClient = client ?? http.Client();

  String get _baseUrl => dotenv.get('mainUrl', fallback: '');

  /// Creates a new dispatching request
  Future<MyRequestsModel> dispatchingRequest({
    required int motorBikerId,
    required int clientId,
    required String requestType,
    required DateTime requestedTime,
    required String originLocation,
    required String destinationLocation,
    required String status,
  }) async {
    // Format the DateTime to 'yyyy-MM-ddTHH:mm:ss'
    final String formattedRequestedTime =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(requestedTime);
    final String now =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());

    // Build the request body
    final Map<String, dynamic> requestBody = {
      'motorBiker': {'id': motorBikerId},
      'client': {'id': clientId},
      'requestType': requestType,
      'requestedTime': formattedRequestedTime,
      'createdAt': now,
      'updatedAt': now,
      'originLocation': originLocation,
      'destinationLocation': destinationLocation,
      'status': status,
    };

    try {
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final Uri url = Uri.parse('$_baseUrl/requests');

      final http.Response response = await httpClient!.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      final Map<String, dynamic> results = jsonDecode(response.body);

      if (kDebugMode) {
        print('Request Response [${response.statusCode}]: $results');
      }

      if (response.statusCode == 200) {
        return MyRequestsModel.fromJson(results);
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        return MyRequestsModel.fromJson(results);
      } else {
        return MyRequestsModel(
          success: false,
          message: _defaultErrorMessage,
          data: null,
        );
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('JSON Format Error: $e');
      }
      return MyRequestsModel(
        success: false,
        message: 'Invalid response format from server',
        data: null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Request Error: $e');
      }
      return MyRequestsModel(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Fetches user sent requests by client ID
  Future<UserSentRequestsModel> dispatchingFetchRequest(
    String clientId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final Uri url = Uri.parse(
        '$_baseUrl/requests/client/$clientId?page=$page&size=$size',
      );

      final http.Response response = await httpClient!.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final Map<String, dynamic> results = jsonDecode(response.body);

      if (kDebugMode) {
        print('Fetch Requests Response [${response.statusCode}]: $results');
      }

      if (response.statusCode == 200) {
        return UserSentRequestsModel.fromJson(results);
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        return UserSentRequestsModel.fromJson(results);
      } else {
        return UserSentRequestsModel(
          success: false,
          message: _defaultErrorMessage,
          data: null,
        );
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('JSON Format Error: $e');
      }
      return UserSentRequestsModel(
        success: false,
        message: 'Invalid response format from server',
        data: null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fetch Requests Error: $e');
      }
      return UserSentRequestsModel(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    httpClient?.close();
  }
}
