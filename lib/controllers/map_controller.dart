import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:speed_ios/model/driver_location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapController extends GetxController {
  List<DriverLocationModel> mapModel = <DriverLocationModel>[].obs;
  var markers = RxSet<Marker>();
  var isLoading = false.obs;
  var selectedDriver = DriverLocationModel();

  fetchLocation() async {
    try {
      isLoading(true);
      http.Response response = await http
          .get(Uri.parse("http://localhost:8080/api/v2/get_driver_location"));
      print(response);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        log(result.toString());
        mapModel.addAll(RxList<Map<String, dynamic>>.from(result)
            .map((item) => DriverLocationModel.fromJson(item))
            .toList());
      } else {
        print("error fecting data");
      }
    } catch (e) {
      print("Error while getting data is $e");
    } finally {
      isLoading(false);
      print("Finaly $mapModel");
      createMarkers();
    }
  }

  void createMarkers() {
    mapModel.forEach((marker) {
      markers.add(Marker(
          markerId: MarkerId(marker.id.toString()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: LatLng(marker.latitude!.floorToDouble(),
              marker.longitude!.floorToDouble()),
          infoWindow:
              InfoWindow(title: marker.driverName, snippet: marker.driverPhone),
          onTap: () {
            selectedDriver = marker;
          }));
    });
  }
}
