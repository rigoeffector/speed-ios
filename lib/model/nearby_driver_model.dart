class NearbyDriverModel {
  int? statusCode;
  bool success = false;
  String? message;
  List<NearbyDriverData>? nearbyDriverData;

  NearbyDriverModel(
      {this.statusCode,
      required this.success,
      this.message,
      this.nearbyDriverData});

  NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'] ?? false;
    message = json['message'];
    if (json['nearby_driver_data'] != null) {
      nearbyDriverData = <NearbyDriverData>[];
      json['nearby_driver_data'].forEach((v) {
        nearbyDriverData!.add(NearbyDriverData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['success'] = success;
    data['message'] = message;
    if (nearbyDriverData != null) {
      data['nearby_driver_data'] =
          nearbyDriverData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NearbyDriverData {
  String? id;
  String? driverName;
  String? driverPhone;
  String? driverCategory;
  String? carName;
  String? photo;
  String? color;
  String? carPhoto;
  String? plateNumber;
  String? price;
  String? model;
  String? isOnline;
  String? latitude;
  String? longitude;
  String? paymentMethod;
  String? distance;

  NearbyDriverData(
      {this.id,
      this.driverName,
      this.driverPhone,
      this.driverCategory,
      this.carName,
      this.color,
      this.carPhoto,
      this.photo,
      this.plateNumber,
      this.price,
      this.model,
      this.isOnline,
      this.latitude,
      this.longitude,
      this.paymentMethod,
      this.distance});

  NearbyDriverData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverName = json['driver_name'];
    driverPhone = json['driver_phone'];
    driverCategory = json['driver_category'];
    carName = json['car_name'];
    color = json['color'];
    carPhoto = json['car_photo'];
    photo = json['photo'];
    plateNumber = json['plate_number'];
    price = json['price'];
    model = json['model'];
    isOnline = json['is_online'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    paymentMethod = json['payment_method'];
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
    data['driver_category'] = driverCategory;
    data['car_name'] = carName;
    data['color'] = color;
    data['car_photo'] = carPhoto;
    data['photo'] = photo;
    data['plate_number'] = plateNumber;
    data['price'] = price;
    data['model'] = model;
    data['is_online'] = isOnline;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['payment_method'] = paymentMethod;
    data['distance'] = distance;
    return data;
  }
}
