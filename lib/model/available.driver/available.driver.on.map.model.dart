class AvailableDriverOnMapModel {
  String? message;
  bool  success = false;
  List<AvailableDriverData>? data;

  AvailableDriverOnMapModel({this.message,required this.success, this.data});

  AvailableDriverOnMapModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'] ?? false;
    if (json['data'] != null) {
      data = <AvailableDriverData>[];
      json['data'].forEach((v) {
        data!.add(AvailableDriverData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AvailableDriverData {
  int? id;
  MotorBiker? motorBiker;
  String? currentLocationName;
  double? longitude;
  double? latitude;
  double? price;
  String? paymentStatus;
  String? requestedTime;

  AvailableDriverData(
      {this.id,
      this.motorBiker,
      this.currentLocationName,
      this.longitude,
      this.latitude,
      this.price,
      this.paymentStatus,
      this.requestedTime});

  AvailableDriverData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    motorBiker = json['motorBiker'] != null
        ? MotorBiker.fromJson(json['motorBiker'])
        : null;
    currentLocationName = json['currentLocationName'];
    longitude = json['longitude'];
    latitude = json['latitude'];
    price = json['price'];
    paymentStatus = json['paymentStatus'];
    requestedTime = json['requestedTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (motorBiker != null) {
      data['motorBiker'] = motorBiker!.toJson();
    }
    data['currentLocationName'] = currentLocationName;
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    data['price'] = price;
    data['paymentStatus'] = paymentStatus;
    data['requestedTime'] = requestedTime;
    return data;
  }
}

class MotorBiker {
  int? id;
  String? motorType;
  String? fname;
  String? lname;
  String? phone;
  String? plateNumber;
  String? numeroChase;
  String? status;

  MotorBiker(
      {this.id,
      this.motorType,
      this.fname,
      this.lname,
      this.phone,
      this.plateNumber,
      this.numeroChase,
      this.status});

  MotorBiker.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    motorType = json['motorType'];
    fname = json['fname'];
    lname = json['lname'];
    phone = json['phone'];
    plateNumber = json['plateNumber'];
    numeroChase = json['numeroChase'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['motorType'] = motorType;
    data['fname'] = fname;
    data['lname'] = lname;
    data['phone'] = phone;
    data['plateNumber'] = plateNumber;
    data['numeroChase'] = numeroChase;
    data['status'] = status;
    return data;
  }
}
