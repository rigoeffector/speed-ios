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
  // Courier-specific fields
  final DispatchInfo? dispatchInfo;
  final CourierLocationData? from;
  final CourierLocationData? to;
  final String? packageDescription;
  final String? packageWeight;
  final String? packageDimensions;
  final double? declaredValue;
  final String? specialInstructions;
  final List<CourierCheckpointData> courierCheckpoints;
  final String? courierCheckpointsJson;

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
    this.dispatchInfo,
    this.from,
    this.to,
    this.packageDescription,
    this.packageWeight,
    this.packageDimensions,
    this.declaredValue,
    this.specialInstructions,
    this.courierCheckpoints = const [],
    this.courierCheckpointsJson,
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
      dispatchInfo: json['dispatchInfo'] is Map<String, dynamic>
          ? DispatchInfo.fromJson(json['dispatchInfo'] as Map<String, dynamic>)
          : null,
      from: json['from'] is Map<String, dynamic>
          ? CourierLocationData.fromJson(json['from'] as Map<String, dynamic>)
          : null,
      to: json['to'] is Map<String, dynamic>
          ? CourierLocationData.fromJson(json['to'] as Map<String, dynamic>)
          : null,
      packageDescription: _fromJsonString(json['packageDescription']),
      packageWeight: _fromJsonString(json['packageWeight']),
      packageDimensions: _fromJsonString(json['packageDimensions']),
      declaredValue: (json['declaredValue'] as num?)?.toDouble(),
      specialInstructions: _fromJsonString(json['specialInstructions']),
      courierCheckpoints: (json['courierCheckpoints'] is List)
          ? (json['courierCheckpoints'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CourierCheckpointData.fromJson(e))
              .toList()
          : const [],
      courierCheckpointsJson: _fromJsonString(json['courierCheckpointsJson']),
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
      if (dispatchInfo != null) 'dispatchInfo': dispatchInfo!.toJson(),
      if (from != null) 'from': from!.toJson(),
      if (to != null) 'to': to!.toJson(),
      if (packageDescription != null) 'packageDescription': packageDescription,
      if (packageWeight != null) 'packageWeight': packageWeight,
      if (packageDimensions != null) 'packageDimensions': packageDimensions,
      if (declaredValue != null) 'declaredValue': declaredValue,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      if (courierCheckpoints.isNotEmpty)
        'courierCheckpoints': courierCheckpoints.map((e) => e.toJson()).toList(),
      if (courierCheckpointsJson != null) 'courierCheckpointsJson': courierCheckpointsJson,
    };
  }

  @override
  String toString() =>
      'RequestData(id: $id, requestType: $requestType, status: $status, origin: $originLocation, destination: $destinationLocation, checkpoints: ${courierCheckpoints.length})';
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

class DispatchInfo {
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final bool? manualDispatch;
  final int? priorityLevel;

  const DispatchInfo({
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.manualDispatch,
    this.priorityLevel,
  });

  factory DispatchInfo.fromJson(Map<String, dynamic> json) {
    return DispatchInfo(
      driverId: _parseInt(json['driverId']),
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      manualDispatch: json['manualDispatch'] as bool?,
      priorityLevel: _parseInt(json['priorityLevel']),
    );
  }

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'manualDispatch': manualDispatch,
        'priorityLevel': priorityLevel,
      };

  @override
  String toString() =>
      'DispatchInfo(driverId: $driverId, driverName: $driverName)';
}

class CourierLocationData {
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? receiverName;
  final String? receiverPhone;
  final bool? driverApprovalRequired;
  final bool? driverApproved;
  final bool? receiverApproved;

  const CourierLocationData({
    this.name,
    this.latitude,
    this.longitude,
    this.receiverName,
    this.receiverPhone,
    this.driverApprovalRequired,
    this.driverApproved,
    this.receiverApproved,
  });

  factory CourierLocationData.fromJson(Map<String, dynamic> json) {
    return CourierLocationData(
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      driverApprovalRequired: json['driverApprovalRequired'] as bool?,
      driverApproved: json['driverApproved'] as bool?,
      receiverApproved: json['receiverApproved'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'driverApprovalRequired': driverApprovalRequired,
        'driverApproved': driverApproved,
        'receiverApproved': receiverApproved,
      };

  @override
  String toString() => name ?? '';
}

class CourierCheckpointData {
  final int? id;
  final String? name;
  final double? latitude;
  final double? longitude;
  final int? order;
  final String? notes;
  final String? receiverName;
  final String? receiverPhone;
  final bool? requiresReceiverApproval;
  final String? packageDescription;
  final String? packageWeight;
  final String? specialInstructions;
  final String? checkpointStatus;
  final bool? otpVerified;
  final int? otpAttempts;
  final String? approvedAt;
  final String? completedAt;
  final String? approvedBy;
  final String? deliveryNotes;
  final String? otpVerifiedAt;
  final String? otpGeneratedAt;
  final String? otpExpiresAt;

  const CourierCheckpointData({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.order,
    this.notes,
    this.receiverName,
    this.receiverPhone,
    this.requiresReceiverApproval,
    this.packageDescription,
    this.packageWeight,
    this.specialInstructions,
    this.checkpointStatus,
    this.otpVerified,
    this.otpAttempts,
    this.approvedAt,
    this.completedAt,
    this.approvedBy,
    this.deliveryNotes,
    this.otpVerifiedAt,
    this.otpGeneratedAt,
    this.otpExpiresAt,
  });

  DateTime? get approvedDateTime =>
      approvedAt != null ? DateTime.tryParse(approvedAt!) : null;
  DateTime? get completedDateTime =>
      completedAt != null ? DateTime.tryParse(completedAt!) : null;
  DateTime? get otpVerifiedDateTime =>
      otpVerifiedAt != null ? DateTime.tryParse(otpVerifiedAt!) : null;
  DateTime? get otpGeneratedDateTime =>
      otpGeneratedAt != null ? DateTime.tryParse(otpGeneratedAt!) : null;
  DateTime? get otpExpiresDateTime =>
      otpExpiresAt != null ? DateTime.tryParse(otpExpiresAt!) : null;

  factory CourierCheckpointData.fromJson(Map<String, dynamic> json) {
    return CourierCheckpointData(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      order: json['order'] as int?,
      notes: json['notes'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      requiresReceiverApproval: json['requiresReceiverApproval'] as bool?,
      packageDescription: json['packageDescription'] as String?,
      packageWeight: json['packageWeight'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      checkpointStatus: json['checkpointStatus'] as String?,
      otpVerified: json['otpVerified'] as bool?,
      otpAttempts: json['otpAttempts'] as int?,
      approvedAt: json['approvedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      approvedBy: json['approvedBy'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
      otpVerifiedAt: json['otpVerifiedAt'] as String?,
      otpGeneratedAt: json['otpGeneratedAt'] as String?,
      otpExpiresAt: json['otpExpiresAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = {};
    if (id != null) m['id'] = id;
    m['name'] = name;
    if (latitude != null) m['latitude'] = latitude;
    if (longitude != null) m['longitude'] = longitude;
    if (order != null) m['order'] = order;
    if (notes != null) m['notes'] = notes;
    if (receiverName != null) m['receiverName'] = receiverName;
    if (receiverPhone != null) m['receiverPhone'] = receiverPhone;
    if (requiresReceiverApproval != null)
      m['requiresReceiverApproval'] = requiresReceiverApproval;
    if (packageDescription != null) m['packageDescription'] = packageDescription;
    if (packageWeight != null) m['packageWeight'] = packageWeight;
    if (specialInstructions != null) m['specialInstructions'] = specialInstructions;
    if (checkpointStatus != null) m['checkpointStatus'] = checkpointStatus;
    if (otpVerified != null) m['otpVerified'] = otpVerified;
    if (otpAttempts != null) m['otpAttempts'] = otpAttempts;
    if (approvedAt != null) m['approvedAt'] = approvedAt;
    if (completedAt != null) m['completedAt'] = completedAt;
    if (approvedBy != null) m['approvedBy'] = approvedBy;
    if (deliveryNotes != null) m['deliveryNotes'] = deliveryNotes;
    if (otpVerifiedAt != null) m['otpVerifiedAt'] = otpVerifiedAt;
    if (otpGeneratedAt != null) m['otpGeneratedAt'] = otpGeneratedAt;
    if (otpExpiresAt != null) m['otpExpiresAt'] = otpExpiresAt;
    return m;
  }

  @override
  String toString() => name ?? '';
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final s = v.toString().trim();
  return int.tryParse(s);
}