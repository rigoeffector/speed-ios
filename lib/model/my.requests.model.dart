class MyRequestsModel {
  final String? message;
  final bool success;
  final RequestData? data;

  const MyRequestsModel({
    this.message,
    required this.success,
    this.data,
  });

  factory MyRequestsModel.fromJson(Map<String, dynamic> json) {
    return MyRequestsModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: _parseData(json['data']),
    );
  }

  static RequestData? _parseData(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return RequestData.fromJson(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return RequestData.fromJson(raw.first as Map<String, dynamic>);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'data': data?.toJson() ?? {},
    };
  }

  /// Convenience for callers expecting a list
  List<RequestData> get dataAsList => data == null ? <RequestData>[] : <RequestData>[data!];

  @override
  String toString() =>
      'MyRequestsModel(success: $success, message: $message, hasData: ${data != null})';
}

class RequestData {
  final int? id;
  final MotorBiker? motorBiker;
  final Client? client;
  final String? requestType;
  final String? requestedTime;
  final String? createdAt;
  final String? updatedAt;
  final String? originLocation;
  final String? destinationLocation;
  final String? status;
  final String? motorType;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? cancelledAt;

  const RequestData({
    this.id,
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
    this.cancelledAt,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      id: _parseInt(json['id']),
      motorBiker: json['motorBiker'] is Map<String, dynamic>
          ? MotorBiker.fromJson(json['motorBiker'] as Map<String, dynamic>)
          : null,
      client: json['client'] is Map<String, dynamic>
          ? Client.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      requestType: _fromJsonString(json['requestType']),
      requestedTime: _fromJsonString(json['requestedTime']),
      createdAt: _fromJsonString(json['createdAt']),
      updatedAt: _fromJsonString(json['updatedAt']),
      originLocation: _fromJsonString(json['originLocation']),
      destinationLocation: _fromJsonString(json['destinationLocation']),
      status: _fromJsonString(json['status']),
      motorType: _fromJsonString(json['motorType']),
      cancelledBy: _fromJsonString(json['cancelledBy']),
      cancellationReason: _fromJsonString(json['cancellationReason']),
      cancelledAt: _fromJsonString(json['cancelledAt']),
    );
  }

  // Optional: parse createdAt/requestedTime into DateTime
  DateTime? get requestedDateTime => _parseDateTime(requestedTime);
  DateTime? get createdDateTime => _parseDateTime(createdAt);
  DateTime? get updatedDateTime => _parseDateTime(updatedAt);
  DateTime? get cancelledDateTime => _parseDateTime(cancelledAt);

  static String? _fromJsonString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return (s.isEmpty || s.toLowerCase() == 'null') ? null : s;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    try {
      return int.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTime(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motorBiker': motorBiker?.toJson(),
      'client': client?.toJson(),
      'requestType': requestType,
      'requestedTime': requestedTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'originLocation': originLocation,
      'destinationLocation': destinationLocation,
      'status': status,
      'motorType': motorType,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt,
    };
  }

  @override
  String toString() =>
      'RequestData(id: $id, requestType: $requestType, status: $status, origin: $originLocation, destination: $destinationLocation)';
}

class MotorBiker {
  final int? id;
  final String? motorType;
  final String? membershipId;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? plateNumber;
  final String? numeroChase;
  final String? status;
  final String? deviceToken;
  final bool speedDriverAccess;

  const MotorBiker({
    this.id,
    this.motorType,
    this.membershipId,
    this.fname,
    this.lname,
    this.phone,
    this.plateNumber,
    this.numeroChase,
    this.status,
    this.deviceToken,
    this.speedDriverAccess = false,
  });

  factory MotorBiker.fromJson(Map<String, dynamic> json) {
    return MotorBiker(
      id: _parseInt(json['id']),
      motorType: RequestData._fromJsonString(json['motorType']),
      membershipId: RequestData._fromJsonString(json['membershipId']),
      fname: RequestData._fromJsonString(json['fname']),
      lname: RequestData._fromJsonString(json['lname']),
      phone: RequestData._fromJsonString(json['phone']),
      plateNumber: RequestData._fromJsonString(json['plateNumber']),
      numeroChase: RequestData._fromJsonString(json['numeroChase']),
      status: RequestData._fromJsonString(json['status']),
      deviceToken: RequestData._fromJsonString(json['deviceToken']),
      speedDriverAccess: _parseBool(json['speedDriverAccess']),
    );
  }

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motorType': motorType,
      'membershipId': membershipId,
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'plateNumber': plateNumber,
      'numeroChase': numeroChase,
      'status': status,
      'deviceToken': deviceToken,
      'speedDriverAccess': speedDriverAccess,
    };
  }

  @override
  String toString() =>
      'MotorBiker(id: $id, name: $fname $lname, phone: $phone, plate: $plateNumber)';
}

class Client {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;
  final String? deviceToken;
  final String? verificationCode;
  final String? verificationCodeExpiry;

  const Client({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
    this.deviceToken,
    this.verificationCode,
    this.verificationCodeExpiry,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: _parseInt(json['id']),
      fname: RequestData._fromJsonString(json['fname']),
      lname: RequestData._fromJsonString(json['lname']),
      phone: RequestData._fromJsonString(json['phone']),
      status: RequestData._fromJsonString(json['status']),
      deviceToken: RequestData._fromJsonString(json['deviceToken']),
      verificationCode: RequestData._fromJsonString(json['verificationCode']),
      verificationCodeExpiry: RequestData._fromJsonString(json['verificationCodeExpiry']),
    );
  }

  DateTime? get verificationCodeExpiryDateTime =>
      verificationCodeExpiry == null ? null : DateTime.tryParse(verificationCodeExpiry!);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'status': status,
      'deviceToken': deviceToken,
      'verificationCode': verificationCode,
      'verificationCodeExpiry': verificationCodeExpiry,
    };
  }

  @override
  String toString() =>
      'Client(id: $id, name: $fname $lname, phone: $phone, status: $status)';
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final s = v.toString().trim();
  return int.tryParse(s);
}