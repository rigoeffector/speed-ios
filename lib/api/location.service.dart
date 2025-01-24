import 'dart:convert';

import 'package:speed_ios/model/client.favorite.location.model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speed_ios/model/available.driver/available.driver.on.map.model.dart';
import 'package:speed_ios/model/nearby_driver_model.dart';

import '../model/client.location.model.dart';

class LocationService {
  Future<AvailableDriverOnMapModel> fetchAvailableDriverLocation() async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.get(
      Uri.parse('${dotenv.get('mainUrl')}/available-motors'),
      headers: headers,
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      AvailableDriverOnMapModel availableDriverOnMapModel =
          AvailableDriverOnMapModel.fromJson(results);
      return availableDriverOnMapModel;
    } else if (response.statusCode == 400) {
      AvailableDriverOnMapModel availableDriverOnMapModel =
          AvailableDriverOnMapModel.fromJson(results);
      return availableDriverOnMapModel;
    } else {
      AvailableDriverOnMapModel availableDriverOnMapModel =
          AvailableDriverOnMapModel.fromJson(results);
      return availableDriverOnMapModel;
    }
  }

  Future<NearbyDriverModel> fetchNearbyDriveerLocationInfo(String latitude,
      String longitude, String radius, String paymentMethod) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/fetch_nearby_driver'),
        headers: headers,
        body: json.encode({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius': radius.toString(),
          'paymentMethod': paymentMethod.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    } else if (response.statusCode == 400) {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    } else {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    }
  }

  Future<CreateClientLocationModel> createClientFavoriteLocation(
      String latitude,
      String longitude,
      String clientId,
      String title,
      String address,
      String phone) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/save_favorite_location'),
        headers: headers,
        body: json.encode({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'clientId': clientId.toString(),
          'title': title.toString(),
          'address': address.toString(),
          'phone': phone.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);

    print("SSAVE $results");
    if (response.statusCode == 200) {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    } else if (response.statusCode == 400) {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    } else {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    }
  }

  Future<ClientFavoriteLocationModel> getClientFavoriteLocation(
      String clientId) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/fetch_favorite_location'),
        headers: headers,
        body: json.encode({
          'clientId': clientId.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    } else if (response.statusCode == 400) {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    } else {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    }
  }
}
