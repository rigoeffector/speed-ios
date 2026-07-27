import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNearDriverModel {
  String? carColor;
  String? status;
  String? driverPhone;
  String? carPlate;
  String? driverId;
  String? carName;
  NearPosition? position;
  String? driverName;

  FirebaseNearDriverModel(
      {this.carColor,
      this.status,
      this.driverPhone,
      this.carPlate,
      this.driverId,
      this.carName,
      this.position,
      this.driverName});

  factory FirebaseNearDriverModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;

    return FirebaseNearDriverModel(
      carColor: data["carColor"],
      status: data["status"],
      driverPhone: data["driverPhone"],
      driverId: data["driverId"],
      position: data["position"] != null
          ? NearPosition.fromJson(data['position'])
          : null,
      driverName: data["driverName"],
    );
  }

   
}

class NearPosition {
  List<double>? geopoint;
  String? geohash;

  NearPosition({this.geopoint, this.geohash});

  NearPosition.fromJson(Map<String, dynamic> json) {
    geopoint = json['geopoint'].cast<double>();
    geohash = json['geohash'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['geopoint'] = geopoint;
    data['geohash'] = geohash;
    return data;
  }
}
