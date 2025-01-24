class DriverDataFoundModel {
  int? statusCode;
  bool? success;
  String? message;
  DriverFoundData? driverFoundData;

  DriverDataFoundModel(
      {this.statusCode, this.success, this.message, this.driverFoundData});

  DriverDataFoundModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'];
    message = json['message'];
    driverFoundData = json['driver_found_data'] != null
        ? DriverFoundData.fromJson(json['driver_found_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['success'] = success;
    data['message'] = message;
    if (driverFoundData != null) {
      data['driver_found_data'] = driverFoundData!.toJson();
    }
    return data;
  }
}

class DriverFoundData {
  String? id;
  String? driverId;
  String? driverName;
  String? driverPhone;
  String? driverPhoto;
  String? carColor;
  String? carPhoto;
  String? carName;
  String? carSeats;
  String? carPlateNumber;
  String? status;

  DriverFoundData(
      {this.id,
      this.driverId,
      this.driverName,
      this.driverPhone,
      this.driverPhoto,
      this.carColor,
      this.carPhoto,
      this.carName,
      this.carSeats,
      this.carPlateNumber,
      this.status});

  DriverFoundData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverId = json['driver_id'];
    driverName = json['driver_name'];
    driverPhone = json['driver_phone'];
    driverPhoto = json['driver_photo'];
    carColor = json['car_color'];
    carPhoto = json['car_photo'];
    carName = json['car_name'];
    carSeats = json['car_seats'];
    carPlateNumber = json['car_plate_number'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['driver_id'] = driverId;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
    data['driver_photo'] = driverPhoto;
    data['car_color'] = carColor;
    data['car_photo'] = carPhoto;
    data['car_name'] = carName;
    data['car_seats'] = carSeats;
    data['car_plate_number'] = carPlateNumber;
    data['status'] = status;
    return data;
  }
}
