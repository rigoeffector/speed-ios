import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/accepted_request.dart';
import '../model/car_category_model.dart';
import '../model/city_model.dart';
import '../model/driver_location.dart';

class HttpService {
  final String localUrl = '${dotenv.get('mainUrl')}'; // Home
  // final String localUrl = 'http://192.168.8.101:8080/api/v2/'; // Office
  final String serverUrl = 'https://api.mopay.com/';
  String? query;
  final String _getCity = "get_city";
  final String _getCarCategory = "get_car_categories";
  final String _getAvailable = "get_online_driver_location";
  final String _getAccepted = "get_my_accepted_request";

  postData(data, apiUrl) async {
    var fullUrl = localUrl + apiUrl;
    print("POST_URL $fullUrl");
    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setHeaders());
  }

  Future<List<CityModel>> getCities(String query) async {
    var fullUrl = localUrl + _getCity;
    if (kDebugMode) {
      print("URL $fullUrl");
    }
    final res = await http.get(Uri.parse(fullUrl));

    if (res.statusCode == 200) {
      final List city = json.decode(res.body);
      return city.map((model) => CityModel.fromJson(model)).where((campus) {
        final lowerName = campus.name?.toLowerCase();
        final queryLower = query.toLowerCase();
        return lowerName!.contains(queryLower);
      }).toList();
    } else {
      throw Exception();
    }
  }

  Future<List<CarCategoryModel>> getCarCategories(String query) async {
    var fullUrl = localUrl + _getCarCategory;
    if (kDebugMode) {
      print("URL $fullUrl");
    }
    final res = await http.get(Uri.parse(fullUrl));

    if (res.statusCode == 200) {
      final List car = json.decode(res.body);
      return car.map((model) => CarCategoryModel.fromJson(model)).where((item) {
        final lowerName = item.title?.toLowerCase();
        final queryLower = query.toLowerCase();
        return lowerName!.contains(queryLower);
      }).toList();
    } else {
      throw Exception();
    }
  }

  Future<List<DriverLocationModel>> getAvailableDriver(String query) async {
    var fullUrl = localUrl + _getAvailable;
    if (kDebugMode) {
      print("URL $fullUrl");
    }
    final res = await http.get(Uri.parse(fullUrl));

    if (res.statusCode == 200) {
      final List car = json.decode(res.body);
      if (kDebugMode) {
        print("DATA $car");
      }
      return car
          .map((model) => DriverLocationModel.fromJson(model))
          .where((item) {
        final lowerName = item.driverName?.toLowerCase();
        final queryLower = query.toLowerCase();
        return lowerName!.contains(queryLower);
      }).toList();
    } else {
      throw Exception();
    }
  }

  Future<List<AcceptedRequestModel>> getMyAcceptedRequest(
      String query, String params) async {
    var fullUrl = '$localUrl$_getAccepted/$params';
    if (kDebugMode) {
      print("URL $fullUrl");
    }
    final res = await http.get(Uri.parse(fullUrl));

    if (res.statusCode == 200) {
      final List car = json.decode(res.body);
      if (kDebugMode) {
        print("DATA $car");
      }
      return car
          .map((model) => AcceptedRequestModel.fromJson(model))
          .where((item) {
        final lowerName = item.driverName?.toLowerCase();
        final queryLower = query.toLowerCase();
        return lowerName!.contains(queryLower);
      }).toList();
    } else {
      throw Exception();
    }
  }

  getData(apiUrl, params) async {
    var fullUrl = localUrl + apiUrl + params;
    http.Response response = await http.get(
      Uri.parse(fullUrl),
    );
    if (kDebugMode) {
      print(response);
    }
    try {
      if (response.statusCode == 200) {
        return response;
      } else {
        return 'failed';
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return 'failed';
    }
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Token': 'app:FIl07m8rWmWddv9W3EsD44vD0eftCEBY'
      };
  _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    return '?token=$token';
  }
}
