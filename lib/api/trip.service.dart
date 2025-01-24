// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speed_ios/model/trip/confirm.trip.model.dart';

class TripService {
  Future<ConfrimTripModel> fetchCarCategories(
      String clientId,
      String tripType,
      String price,
      String paymenyMode,
      String source,
      String destination,
      String sLatitude,
      String sLongitude,
      String dLatitude,
      String dLongitude) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/client/ride_request'),
        headers: headers,
        body: jsonEncode({
          "clientId": clientId,
          "tripType": tripType,
          "price": price,
          "paymenyMode": paymenyMode,
          "source": source,
          "destination": destination,
          "sLatitude": sLatitude,
          "sLongitude": sLongitude,
          "dLatitude": dLatitude,
          "dLongitude": dLongitude
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    print("RESSULT $results");
    if (response.statusCode == 200) {
      ConfrimTripModel confrimTripModel = ConfrimTripModel.fromJson(results);

      return confrimTripModel;
    } else if (response.statusCode == 400) {
      ConfrimTripModel confrimTripModel = ConfrimTripModel.fromJson(results);
      return confrimTripModel;
    } else {
      ConfrimTripModel confrimTripModel = ConfrimTripModel.fromJson(results);
      return confrimTripModel;
    }
  }
}
