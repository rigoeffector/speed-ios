class MyRequestsModel {
  String? message;
  bool success = false;
  List<Data>? data;

  MyRequestsModel({this.message, required this.success, this.data});

  MyRequestsModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'] ?? false;
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  int? id;
  MotorBiker? motorBiker;
  Client? client;
  String? requestType;
  String? requestedTime;
  String? createdAt;
  String? updatedAt;
  String? originLocation;
  String? destinationLocation;
  String? status;

  Data(
      {this.id,
      this.motorBiker,
      this.client,
      this.requestType,
      this.requestedTime,
      this.createdAt,
      this.updatedAt,
      this.originLocation,
      this.destinationLocation,
      this.status});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    motorBiker = json['motorBiker'] != null
        ? MotorBiker.fromJson(json['motorBiker'])
        : null;
    client = json['client'] != null ? Client.fromJson(json['client']) : null;
    requestType = json['requestType'];
    requestedTime = json['requestedTime'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    originLocation = json['originLocation'];
    destinationLocation = json['destinationLocation'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (motorBiker != null) {
      data['motorBiker'] = motorBiker!.toJson();
    }
    if (client != null) {
      data['client'] = client!.toJson();
    }
    data['requestType'] = requestType;
    data['requestedTime'] = requestedTime;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['originLocation'] = originLocation;
    data['destinationLocation'] = destinationLocation;
    data['status'] = status;
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

class Client {
  int? id;
  String? fname;
  String? lname;
  String? phone;
  String? status;

  Client({this.id, this.fname, this.lname, this.phone, this.status});

  Client.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fname = json['fname'];
    lname = json['lname'];
    phone = json['phone'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fname'] = fname;
    data['lname'] = lname;
    data['phone'] = phone;
    data['status'] = status;
    return data;
  }
}
