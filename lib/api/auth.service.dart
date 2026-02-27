// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:speed_ios/model/my.requests.model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speed_ios/model/auth/client.profile.model.dart';
import 'package:speed_ios/model/auth/register.client.model.dart';
import 'package:speed_ios/model/auth/update.client.model.dart';
import 'package:speed_ios/model/car.category.new.model.dart';
import 'package:speed_ios/model/user.login.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/active_request_model.dart';
import '../model/update.profile.model.dart';
import '../model/verify.otp.model.dart';

class AuthService {
  Future<RegisterClientModel> postRegisterClientInfo(
      String clientPhone, String token, String countryCode) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/clients/create'),
        headers: headers,
        body: json.encode({
          'phone': clientPhone.toString(),
          'deviceToken': token.toString()
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      RegisterClientModel registerClientModel =
          RegisterClientModel.fromJson(results);
      sharedPreferences.setString(
          "currentUser", jsonEncode(registerClientModel.data!.first));
      sharedPreferences.setString("currentUserType", "1");
      sharedPreferences.setString('currentCountryCode', countryCode.toString());
      return registerClientModel;
    } else if (response.statusCode == 400) {
      RegisterClientModel registerClientModel =
          RegisterClientModel.fromJson(results);
      sharedPreferences.setString(
          "currentUser", jsonEncode(registerClientModel.data!.first));
      sharedPreferences.setString("currentUserType", "1");
      sharedPreferences.setString('currentCountryCode', countryCode.toString());
      return registerClientModel;
    } else {
      RegisterClientModel registerClientModel =
          RegisterClientModel.fromJson(results);
      return registerClientModel;
    }
  }

  Future<UserLoginModel> postClientLogin(String email, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/login'),
        headers: headers,
        body: json.encode(
            {'email': email.toString(), 'password': password.toString()}));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      UserLoginModel model = UserLoginModel.fromJson(results);

      sharedPreferences.setString(
          'currentUser', jsonEncode(model.userLoginData));

      return model;
    } else if (response.statusCode == 400) {
      UserLoginModel model = UserLoginModel.fromJson(results);
      return model;
    } else {
      UserLoginModel model = UserLoginModel.fromJson(results);
      return model;
    }
  }

  Future<UpdateProfileModel> postUpdateClientInfoV2(
      String clientId, String clientName, PickedFile imageFile) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final url = Uri.parse('${dotenv.get('mainUrl')}/client/update_info_v2');

    final request = http.MultipartRequest('POST', url);
    final imageBytes = await imageFile.readAsBytes();

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: imageFile.path.split('/').last,
    );
    request.files.add(multipartFile);
    request.fields['verifyId'] = clientId.toString();
    request.fields['clientName'] = clientName.toString();
    final response = await request.send();
    final responseString = await response.stream.bytesToString();

    Map<String, dynamic> results = jsonDecode(responseString);
    if (kDebugMode) {
      print("Client DATA $results");
    }
    if (response.statusCode == 200) {
      UpdateProfileModel updateClientInfoModel =
          UpdateProfileModel.fromJson(results);

      sharedPreferences.setString(
          'currentUser', jsonEncode(updateClientInfoModel.updateData));

      return updateClientInfoModel;
    } else if (response.statusCode == 400) {
      UpdateProfileModel updateClientInfoModel =
          UpdateProfileModel.fromJson(results);
      return updateClientInfoModel;
    } else {
      UpdateProfileModel updateClientInfoModel =
          UpdateProfileModel.fromJson(results);
      return updateClientInfoModel;
    }
  }

  Future<UpdateClientInfoModel> postUpdateClientInfo(
      String clientId, String fname, String lname, String deviceToken) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    print(clientId.toString());
    final url =
        Uri.parse('${dotenv.get('mainUrl')}/clients/${clientId.toString()}');
    var response = await http.put(url,
        headers: headers,
        body: json.encode({
          'fname': fname.toString(),
          'lname': lname.toString(),
          'status': "ACTIVE",
          'deviceToken': deviceToken.toString()
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (kDebugMode) {
      print("Client DATA $results");
    }
    if (response.statusCode == 200) {
      UpdateClientInfoModel updateClientInfoModel =
          UpdateClientInfoModel.fromJson(results);

      sharedPreferences.setString(
          'currentUser', jsonEncode(updateClientInfoModel.data!));

      sharedPreferences.setString(
          'currentUserProfile', jsonEncode(updateClientInfoModel.data!));

      return updateClientInfoModel;
    } else if (response.statusCode == 400) {
      UpdateClientInfoModel updateClientInfoModel =
          UpdateClientInfoModel.fromJson(results);
      sharedPreferences.setString(
          'currentUser', jsonEncode(updateClientInfoModel.data!));
      return updateClientInfoModel;
    } else {
      UpdateClientInfoModel updateClientInfoModel =
          UpdateClientInfoModel.fromJson(results);
      sharedPreferences.setString(
          'currentUser', jsonEncode(updateClientInfoModel.data!));
      return updateClientInfoModel;
    }
  }

  Future<CarCategoryNewModel> fetchCarCategories() async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.get(
      Uri.parse('${dotenv.get('mainUrl')}/client/fetch_car_categories'),
      headers: headers,
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      CarCategoryNewModel carCategoryNewModel =
          CarCategoryNewModel.fromJson(results);
      return carCategoryNewModel;
    } else if (response.statusCode == 400) {
      CarCategoryNewModel carCategoryNewModel =
          CarCategoryNewModel.fromJson(results);
      return carCategoryNewModel;
    } else {
      CarCategoryNewModel carCategoryNewModel =
          CarCategoryNewModel.fromJson(results);
      return carCategoryNewModel;
    }
  }

  Future<ClientProfileModel> fetchingAllClientProfileInfo(String userId) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/clients/${userId.toString()}'),
      headers: headers,
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    print(results);
    if (response.statusCode == 200) {
      ClientProfileModel profileModel = ClientProfileModel.fromJson(results);
      return profileModel;
    } else if (response.statusCode == 400) {
      ClientProfileModel profileModel = ClientProfileModel.fromJson(results);
      return profileModel;
    } else {
      ClientProfileModel profileModel = ClientProfileModel.fromJson(results);
      return profileModel;
    }
  }

  Future<MyRequestsModel> postCLientREquest(
      int motorBikerId,
      int clientId,
      String requestType,
      DateTime requestedTime,
      String originLocation,
      String destinationLocation,
      String status) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    // Format the DateTime to 'yyyy-MM-ddTHH:mm:ss'
    String formattedDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(requestedTime);
    String now = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());

    final url = Uri.parse('${dotenv.get('mainUrl')}/requests');
    var response = await http.post(url,
        headers: headers,
        body: json.encode({
          'motorBiker': {'id': motorBikerId},
          'client': {'id': clientId},
          'requestType': requestType,
          'requestedTime': formattedDate,
          'createdAt': now, // Set createdAt to the current date and time
          'updatedAt': now, // Set updatedAt to the current date and time
          'originLocation': originLocation,
          'destinationLocation': destinationLocation,
          'status': status
        }));

    Map<String, dynamic> results = jsonDecode(response.body);

    if (response.statusCode == 200) {
      MyRequestsModel updateClientInfoModel = MyRequestsModel.fromJson(results);
      if (kDebugMode) {
        print("Client DATA ${updateClientInfoModel.success}");
      }

      return updateClientInfoModel;
    } else if (response.statusCode == 400) {
      MyRequestsModel updateClientInfoModel = MyRequestsModel.fromJson(results);
      return updateClientInfoModel;
    } else {
      MyRequestsModel updateClientInfoModel = MyRequestsModel.fromJson(results);
      return updateClientInfoModel;
    }
  }

  Future<MyRequestsModel> cancelSentRequestStatus(
      String requestId, String status, String? cancellationReason) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Build query parameters
    Map<String, String> queryParams = {
      'cancelledBy': 'CLIENT',
    };

    // Add cancellation reason if provided
    if (cancellationReason != null && cancellationReason.isNotEmpty) {
      queryParams['cancellationReason'] = cancellationReason;
    }

    // Build URI with query parameters
    Uri uri = Uri.parse('${dotenv.get('mainUrl')}/requests/$requestId/cancel')
        .replace(queryParameters: queryParams);

    // Log request details
    print('=== REQUEST ===');
    print('Method: PATCH');
    print('URL: $uri');
    print('Headers: $headers');
    print('Query Params: $queryParams');
    print('===============\n');

    var response = await http.patch(
      uri,
      headers: headers,
    );

    // Log response details
    print('=== RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
    print('================\n');

    Map<String, dynamic> results = jsonDecode(response.body);

    if (response.statusCode == 200) {
      MyRequestsModel updateSentRequestModel =
          MyRequestsModel.fromJson(results);
      return updateSentRequestModel;
    } else if (response.statusCode == 400) {
      MyRequestsModel updateSentRequestModel =
          MyRequestsModel.fromJson(results);
      return updateSentRequestModel;
    } else {
      MyRequestsModel updateSentRequestModel =
          MyRequestsModel.fromJson(results);
      return updateSentRequestModel;
    }
  }

  // Verify OTP
  Future<VerifyOtpModel> postVerifyOtp(String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/clients/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return VerifyOtpModel.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return VerifyOtpModel(
          success: false,
          message: errorResponse['message'] ?? 'Verification failed',
        );
      }
    } catch (e) {
      return VerifyOtpModel(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Resend OTP
  Future<VerifyOtpModel> postResendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${dotenv.get('mainUrl')}/clients/resend-otp'), // Adjust endpoint as needed
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return VerifyOtpModel(
          success: true,
          message: jsonResponse['message'] ?? 'OTP sent successfully',
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        return VerifyOtpModel(
          success: false,
          message: errorResponse['message'] ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      return VerifyOtpModel(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ActiveRequestModel> getActiveRequest(int clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('${dotenv.get('mainUrl')}/requests/active/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint(jsonData.toString());
        return ActiveRequestModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // No active request found
        return ActiveRequestModel(
          success: true,
          message: 'No active request',
          data: null,
        );
      } else {
        throw Exception(
            'Failed to load active request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching active request: $e');
    }
  }
}
