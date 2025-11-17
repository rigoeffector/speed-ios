class AvailableDriverOnMapModel {
  final String? message;
  final bool success;
  final List<AvailableDriverData> data; // Non-nullable: always [] if empty/null

  const AvailableDriverOnMapModel({
    required this.message,
    required this.success,
    required this.data,
  });

  factory AvailableDriverOnMapModel.fromJson(Map<String, dynamic> json) {
    return AvailableDriverOnMapModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: _parseData(json['data']),
    );
  }

  static List<AvailableDriverData> _parseData(dynamic dataJson) {
    if (dataJson == null) {
      print('Info: data is null, defaulting to empty list');
      return <AvailableDriverData>[];
    }

    if (dataJson is List) {
      // Standard: List of maps
      return dataJson
          .where((item) => item is Map<String, dynamic>) // Filter invalid
          .cast<Map<String, dynamic>>()
          .map((item) => AvailableDriverData.fromJson(item))
          .toList();
    } else if (dataJson is Map<String, dynamic>) {
      // Fallback: Single object → list of 1
      print('Info: Converted single Map to List for data');
      return <AvailableDriverData>[AvailableDriverData.fromJson(dataJson)];
    } else {
      // Unexpected type
      print('Warning: Unexpected type for data: ${dataJson.runtimeType}. Defaulting to empty list.');
      return <AvailableDriverData>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['message'] = message;
    dataMap['success'] = success;
    if (data.isNotEmpty) {
      dataMap['data'] = data.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }

  @override
  String toString() => 'AvailableDriverOnMapModel(success: $success, dataLength: ${data.length}, message: $message)';
}

class AvailableDriverData {
  final int? id;
  final MotorBiker? motorBiker;
  final String? currentLocationName;
  final double? longitude;
  final double? latitude;
  final double? price; // Changed from int? to double?
  final String? paymentStatus;
  final String? requestedTime;

  const AvailableDriverData({
    this.id,
    this.motorBiker,
    this.currentLocationName,
    this.longitude,
    this.latitude,
    this.price,
    this.paymentStatus,
    this.requestedTime,
  });

  factory AvailableDriverData.fromJson(Map<String, dynamic> json) {
    return AvailableDriverData(
      id: json['id'] as int?,
      motorBiker: json['motorBiker'] != null
          ? MotorBiker.fromJson(json['motorBiker'] as Map<String, dynamic>)
          : null,
      currentLocationName: _fromJsonString(json['currentLocationName']),
      longitude: _toDouble(json['longitude']),
      latitude: _toDouble(json['latitude']),
      price: _toDouble(json['price']), // Use _toDouble instead of casting to int
      paymentStatus: _fromJsonString(json['paymentStatus']),
      requestedTime: _fromJsonString(json['requestedTime']),
    );
  }

  // Helper: Converts "null" string to actual null
  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  // Helper: Safe double conversion
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Optional: DateTime parser for requestedTime
  DateTime? get requestedDateTime => requestedTime != null
      ? DateTime.tryParse(requestedTime!)
      : null;

  // Optional: Get price as int if you need it
  int? get priceAsInt => price?.toInt();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    if (motorBiker != null) {
      dataMap['motorBiker'] = motorBiker!.toJson();
    }
    dataMap['currentLocationName'] = currentLocationName;
    dataMap['longitude'] = longitude;
    dataMap['latitude'] = latitude;
    dataMap['price'] = price;
    dataMap['paymentStatus'] = paymentStatus;
    dataMap['requestedTime'] = requestedTime;
    return dataMap;
  }

  @override
  String toString() => 'AvailableDriverData(id: $id, motorBiker: ${motorBiker?.fullName}, location: $currentLocationName, price: $price)';
}
class MotorBiker {
  final int? id;
  final String? motorType;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? plateNumber;
  final String? chassisNumber;
  final String? vestNumber;
  final String? status;
  final String? deviceToken;
  final bool? speedDriverAccess;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? fullName;

  const MotorBiker({
    this.id,
    this.motorType,
    this.firstName,
    this.lastName,
    this.phone,
    this.plateNumber,
    this.chassisNumber,
    this.vestNumber,
    this.status,
    this.deviceToken,
    this.speedDriverAccess,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.fullName,
  });

  factory MotorBiker.fromJson(Map<String, dynamic> json) {
    return MotorBiker(
      id: json['id'] as int?,
      motorType: _fromJsonString(json['motorType']),
      firstName: _fromJsonString(json['firstName']),
      lastName: _fromJsonString(json['lastName']),
      phone: _fromJsonString(json['phone']),
      plateNumber: _fromJsonString(json['plateNumber']),
      chassisNumber: _fromJsonString(json['chassisNumber']),
      vestNumber: _fromJsonString(json['vestNumber']),
      status: _fromJsonString(json['status']),
      deviceToken: _fromJsonString(json['deviceToken']),
      speedDriverAccess: json['speedDriverAccess'] as bool?,
      isActive: json['isActive'] as bool?,
      createdAt: _fromJsonString(json['createdAt']),
      updatedAt: _fromJsonString(json['updatedAt']),
      fullName: _fromJsonString(json['fullName']),
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  // Optional: DateTime parsers
  DateTime? get createdDateTime => createdAt != null
      ? DateTime.tryParse(createdAt!)
      : null;

  DateTime? get updatedDateTime => updatedAt != null
      ? DateTime.tryParse(updatedAt!)
      : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    dataMap['motorType'] = motorType;
    dataMap['firstName'] = firstName;
    dataMap['lastName'] = lastName;
    dataMap['phone'] = phone;
    dataMap['plateNumber'] = plateNumber;
    dataMap['chassisNumber'] = chassisNumber;
    dataMap['vestNumber'] = vestNumber;
    dataMap['status'] = status;
    dataMap['deviceToken'] = deviceToken;
    dataMap['speedDriverAccess'] = speedDriverAccess;
    dataMap['isActive'] = isActive;
    dataMap['createdAt'] = createdAt;
    dataMap['updatedAt'] = updatedAt;
    dataMap['fullName'] = fullName;
    return dataMap;
  }

  @override
  String toString() => 'MotorBiker(id: $id, fullName: $fullName, phone: $phone, status: $status)';
}