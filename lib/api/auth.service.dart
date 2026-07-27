// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:speed_ios/model/my.requests.model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speed_ios/model/auth/client.profile.model.dart';
import 'package:speed_ios/model/auth/register.client.model.dart';
import 'package:speed_ios/model/auth/update.client.model.dart';
import 'package:speed_ios/model/car.category.new.model.dart';
import 'package:speed_ios/model/client_statistics_model.dart';
import 'package:speed_ios/model/user.login.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/active_request_model.dart';
import '../model/received.sent.requests.model.dart';
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

  Future<bool> updateClientDeviceToken(String clientId, String deviceToken) async {
  Map<String, String> headers = {'Content-Type': 'application/json'};

  try {
    var response = await http.put(
      Uri.parse('${dotenv.get('mainUrl')}/clients/$clientId'),
      headers: headers,
      body: json.encode({
        'device_token': deviceToken.toString(),
      }),
    );



    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}


  Future<UpdateClientInfoModel> postUpdateClientInfo(
      String clientId, String fname, String lname) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};


    final url =
        Uri.parse('${dotenv.get('mainUrl')}/clients/${clientId.toString()}');
    var response = await http.put(url,
        headers: headers,
        body: json.encode({
          'fname': fname.toString(),
          'lname': lname.toString(),
          'status': "ACTIVE"
        }));

    Map<String, dynamic> results = jsonDecode(response.body);


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
      Map<String, dynamic> requestBody, {String requestType = 'RIDE'}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    final path = requestType == 'COURIER' ? '/courier/requests' : '/requests';
    final url = Uri.parse('${dotenv.get('mainUrl')}$path');
    var response = await http.post(url,
        headers: headers,
        body: json.encode(requestBody));
 
    Map<String, dynamic> results = jsonDecode(response.body);
  
    if (response.statusCode == 200) {
      MyRequestsModel updateClientInfoModel = MyRequestsModel.fromJson(results);
   

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

   
    var response = await http.patch(
      uri,
      headers: headers,
    );

  
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

  // Verify OTP — referral code is now optional and passed in, not hardcoded
Future<VerifyOtpModel> postVerifyOtp(
  String phone,
  String otp, {
  String? referralCode,
}) async {
  try {
    final Map<String, dynamic> body = {
      'phone': phone,
      'otp': otp,
    };

    if (referralCode != null && referralCode.trim().isNotEmpty) {
      body['referralCode'] = referralCode.trim();
    }

    final response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/clients/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
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

// NEW: lets a client add a referral code after registration
// Apply a referral code as a client (matches POST /api/referrals/apply)
Future<VerifyOtpModel> postAddReferralCode(
  String clientId,
  String referralCode,
) async {
  try {
    final response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/referrals/apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': referralCode.trim(),
        'clientId': int.tryParse(clientId) ?? clientId,
      }),
    );

    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VerifyOtpModel(
        success: jsonResponse['success'] ?? true,
        message: jsonResponse['message'] ?? 'Referral code applied successfully',
      );
    } else {
      return VerifyOtpModel(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to apply referral code',
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
    
    
        return ActiveRequestModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // No active request found
        return ActiveRequestModel(
          success: true,
          message: 'No active request',
          data: null,
        );
      } else {
        throw Exception('Failed to load active request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching active request: $e');
    }
  }

  Future<ClientStatisticsModel> fetchClientStatistics(String clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http.get(
        Uri.parse('${dotenv.get('mainUrl')}/clients/$clientId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final payload = jsonDecode(response.body) as Map<String, dynamic>;


      if (response.statusCode == 200) {
        return ClientStatisticsModel.fromJson(payload);
      }

      return ClientStatisticsModel(
        message: payload['message'] as String? ?? 'Failed to load client statistics',
        success: false,
        data: null,
      );
    } catch (e) {
      return ClientStatisticsModel(
        message: 'Error fetching client statistics: $e',
        success: false,
        data: null,
      );
    }
  }

  Future<RequestContent?> getRequestById(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final paths = [
        '/requests/$requestId',
        '/courier/requests/$requestId',
      ];

      for (final path in paths) {
        final response = await http.get(
          Uri.parse('${dotenv.get('mainUrl')}$path'),
          headers: headers,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 404) {
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to load request details: ${response.statusCode}');
        }

        final payload = jsonDecode(response.body);
        if (payload is! Map<String, dynamic>) {
          throw Exception('Unexpected request payload shape');
        }

        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          return RequestContent.fromJson(data);
        }

        if (data is Map) {
          return RequestContent.fromJson(Map<String, dynamic>.from(data));
        }

        return null;
      }

      return null;
    } catch (e) {
      throw Exception('Error fetching request by id: $e');
    }
  }
 
}
