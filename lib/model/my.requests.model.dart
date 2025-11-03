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
  String? motorType;
  String? cancelledBy;
  String? cancellationReason;
  String? cancelledAt;

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
      this.status,
      this.motorType,
      this.cancelledBy,
      this.cancellationReason,
      this.cancelledAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    motorBiker = json['motorBiker'] != null
        ? MotorBiker.fromJson(json['motorBiker'])
        : null;
    client =
        json['client'] != null ? Client.fromJson(json['client']) : null;
    requestType = json['requestType'];
    requestedTime = json['requestedTime'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    originLocation = json['originLocation'];
    destinationLocation = json['destinationLocation'];
    status = json['status'];
    motorType = json['motorType'];
    cancelledBy = json['cancelledBy'];
    cancellationReason = json['cancellationReason'];
    cancelledAt = json['cancelledAt'];
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
    data['motorType'] = motorType;
    data['cancelledBy'] = cancelledBy;
    data['cancellationReason'] = cancellationReason;
    data['cancelledAt'] = cancelledAt;
    return data;
  }
}

class MotorBiker {
  int? id;
  String? motorType;
  String? membershipId;
  String? fname;
  String? lname;
  String? phone;
  String? plateNumber;
  String? numeroChase;
  String? status;
  String? deviceToken;
  bool? speedDriverAccess;

  MotorBiker(
      {this.id,
      this.motorType,
      this.membershipId,
      this.fname,
      this.lname,
      this.phone,
      this.plateNumber,
      this.numeroChase,
      this.status,
      this.deviceToken,
      this.speedDriverAccess});

  MotorBiker.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    motorType = json['motorType'];
    membershipId = json['membershipId'];
    fname = json['fname'];
    lname = json['lname'];
    phone = json['phone'];
    plateNumber = json['plateNumber'];
    numeroChase = json['numeroChase'];
    status = json['status'];
    deviceToken = json['deviceToken'];
    speedDriverAccess = json['speedDriverAccess'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['motorType'] = motorType;
    data['membershipId'] = membershipId;
    data['fname'] = fname;
    data['lname'] = lname;
    data['phone'] = phone;
    data['plateNumber'] = plateNumber;
    data['numeroChase'] = numeroChase;
    data['status'] = status;
    data['deviceToken'] = deviceToken;
    data['speedDriverAccess'] = speedDriverAccess;
    return data;
  }
}

class Client {
  int? id;
  String? fname;
  String? lname;
  String? phone;
  String? status;
  String? deviceToken;
  String? verificationCode;
  String? verificationCodeExpiry;

  Client(
      {this.id,
      this.fname,
      this.lname,
      this.phone,
      this.status,
      this.deviceToken,
      this.verificationCode,
      this.verificationCodeExpiry});

  Client.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fname = json['fname'];
    lname = json['lname'];
    phone = json['phone'];
    status = json['status'];
    deviceToken = json['deviceToken'];
    verificationCode = json['verificationCode'];
    verificationCodeExpiry = json['verificationCodeExpiry'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fname'] = fname;
    data['lname'] = lname;
    data['phone'] = phone;
    data['status'] = status;
    data['deviceToken'] = deviceToken;
    data['verificationCode'] = verificationCode;
    data['verificationCodeExpiry'] = verificationCodeExpiry;
    return data;
  }
}
