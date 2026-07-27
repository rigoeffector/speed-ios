class UserSentRequestsModel {
  final String? message;
  final bool success;
  final RequestData? data;

  const UserSentRequestsModel({
    required this.message,
    required this.success,
    required this.data,
  });

  factory UserSentRequestsModel.fromJson(Map<String, dynamic> json) {
    return UserSentRequestsModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? RequestData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['message'] = message;
    dataMap['success'] = success;
    if (data != null) {
      dataMap['data'] = data!.toJson();
    }
    return dataMap;
  }

  @override
  String toString() => 'UserSentRequestsModel(success: $success, totalItems: ${data?.totalItems}, message: $message)';
}

class RequestData {
  final List<RequestContent> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;
  final int size;

  const RequestData({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
    this.size = 20,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      content: _parseContent(json['content']),
      currentPage: json['currentPage'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
    );
  }

  static List<RequestContent> _parseContent(dynamic contentJson) {
    if (contentJson == null) {
      print('Info: content is null, defaulting to empty list');
      return <RequestContent>[];
    }

    if (contentJson is List) {
      return contentJson
          .where((item) => item is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => RequestContent.fromJson(item))
          .toList();
    } else if (contentJson is Map<String, dynamic>) {
      print('Info: Converted single Map to List for content');
      return <RequestContent>[RequestContent.fromJson(contentJson)];
    } else {
      print('Warning: Unexpected type for content: ${contentJson.runtimeType}. Defaulting to empty list.');
      return <RequestContent>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    if (content.isNotEmpty) {
      dataMap['content'] = content.map((v) => v.toJson()).toList();
    }
    dataMap['currentPage'] = currentPage;
    dataMap['totalItems'] = totalItems;
    dataMap['totalPages'] = totalPages;
    dataMap['size'] = size;
    return dataMap;
  }

  @override
  String toString() => 'RequestData(currentPage: $currentPage, totalItems: $totalItems, totalPages: $totalPages, size: $size, contentLength: ${content.length})';
}

class LocationInfo {
  final String? name;
  final double? latitude;
  final double? longitude;

  const LocationInfo({
    this.name,
    this.latitude,
    this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// Parses originLocation which can be either a String or a Map object.
  static LocationInfo? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return LocationInfo.fromJson(value);
    }
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'null' || lower.isEmpty) return null;
      return LocationInfo(name: value);
    }
    return LocationInfo(name: value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['name'] = name;
    if (latitude != null) dataMap['latitude'] = latitude;
    if (longitude != null) dataMap['longitude'] = longitude;
    return dataMap;
  }

  @override
  String toString() => name ?? '';
}

class Checkpoint {
  final String? name;
  final double? latitude;
  final double? longitude;
  final int? order;

  const Checkpoint({
    this.name,
    this.latitude,
    this.longitude,
    this.order,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['name'] = name;
    if (latitude != null) dataMap['latitude'] = latitude;
    if (longitude != null) dataMap['longitude'] = longitude;
    if (order != null) dataMap['order'] = order;
    return dataMap;
  }

  @override
  String toString() => name ?? '';
}

class CourierLocation {
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? receiverName;
  final String? receiverPhone;
  final bool? driverApprovalRequired;
  final bool? driverApproved;

  const CourierLocation({
    this.name,
    this.latitude,
    this.longitude,
    this.receiverName,
    this.receiverPhone,
    this.driverApprovalRequired,
    this.driverApproved,
  });

  factory CourierLocation.fromJson(Map<String, dynamic> json) {
    return CourierLocation(
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      driverApprovalRequired: json['driverApprovalRequired'] as bool?,
      driverApproved: json['driverApproved'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['name'] = name;
    if (latitude != null) dataMap['latitude'] = latitude;
    if (longitude != null) dataMap['longitude'] = longitude;
    if (receiverName != null) dataMap['receiverName'] = receiverName;
    if (receiverPhone != null) dataMap['receiverPhone'] = receiverPhone;
    if (driverApprovalRequired != null) dataMap['driverApprovalRequired'] = driverApprovalRequired;
    if (driverApproved != null) dataMap['driverApproved'] = driverApproved;
    return dataMap;
  }

  @override
  String toString() => name ?? '';
}

class CourierCheckpoint {
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

  const CourierCheckpoint({
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

  /// DateTime parsers
  DateTime? get approvedDateTime => approvedAt != null ? DateTime.tryParse(approvedAt!) : null;
  DateTime? get completedDateTime => completedAt != null ? DateTime.tryParse(completedAt!) : null;
  DateTime? get otpVerifiedDateTime => otpVerifiedAt != null ? DateTime.tryParse(otpVerifiedAt!) : null;
  DateTime? get otpGeneratedDateTime => otpGeneratedAt != null ? DateTime.tryParse(otpGeneratedAt!) : null;
  DateTime? get otpExpiresDateTime => otpExpiresAt != null ? DateTime.tryParse(otpExpiresAt!) : null;

  factory CourierCheckpoint.fromJson(Map<String, dynamic> json) {
    return CourierCheckpoint(
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
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['name'] = name;
    if (latitude != null) dataMap['latitude'] = latitude;
    if (longitude != null) dataMap['longitude'] = longitude;
    if (order != null) dataMap['order'] = order;
    if (notes != null) dataMap['notes'] = notes;
    if (receiverName != null) dataMap['receiverName'] = receiverName;
    if (receiverPhone != null) dataMap['receiverPhone'] = receiverPhone;
    if (requiresReceiverApproval != null) dataMap['requiresReceiverApproval'] = requiresReceiverApproval;
    if (packageDescription != null) dataMap['packageDescription'] = packageDescription;
    if (packageWeight != null) dataMap['packageWeight'] = packageWeight;
    if (specialInstructions != null) dataMap['specialInstructions'] = specialInstructions;
    if (checkpointStatus != null) dataMap['checkpointStatus'] = checkpointStatus;
    if (otpVerified != null) dataMap['otpVerified'] = otpVerified;
    if (otpAttempts != null) dataMap['otpAttempts'] = otpAttempts;
    if (approvedAt != null) dataMap['approvedAt'] = approvedAt;
    if (completedAt != null) dataMap['completedAt'] = completedAt;
    if (approvedBy != null) dataMap['approvedBy'] = approvedBy;
    if (deliveryNotes != null) dataMap['deliveryNotes'] = deliveryNotes;
    if (otpVerifiedAt != null) dataMap['otpVerifiedAt'] = otpVerifiedAt;
    if (otpGeneratedAt != null) dataMap['otpGeneratedAt'] = otpGeneratedAt;
    if (otpExpiresAt != null) dataMap['otpExpiresAt'] = otpExpiresAt;
    return dataMap;
  }

  @override
  String toString() => name ?? '';
}

class RequestContent {
  final int? id;
  final MotorBiker? motorBiker;
  final Client? client;
  final String? requestType;
  final String? requestedTime;
  final String? createdAt;
  final String? updatedAt;
  final LocationInfo? originLocation;
  final List<Checkpoint> checkpoints;
  final String? destinationLocation;
  final String? status;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final int? priorityLevel;
  final bool? manualDispatch;
  final double? distanceKm;
  final double? actualFare;
  final String? pickupTime;
  final String? dropoffTime;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? cancelledAt;
  // Courier-specific fields
  final CourierLocation? courierFrom;
  final CourierLocation? courierTo;
  final List<CourierCheckpoint> courierCheckpoints;
  final String? packageDescription;
  final String? packageWeight;
  final String? packageDimensions;
  final double? declaredValue;
  final String? specialInstructions;

  const RequestContent({
    this.id,
    this.motorBiker,
    this.client,
    this.requestType,
    this.requestedTime,
    this.createdAt,
    this.updatedAt,
    this.originLocation,
    this.checkpoints = const [],
    this.destinationLocation,
    this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.priorityLevel,
    this.manualDispatch,
    this.distanceKm,
    this.actualFare,
    this.pickupTime,
    this.dropoffTime,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    this.courierFrom,
    this.courierTo,
    this.courierCheckpoints = const [],
    this.packageDescription,
    this.packageWeight,
    this.packageDimensions,
    this.declaredValue,
    this.specialInstructions,
  });

  /// Whether this is a courier request
  bool get isCourier => requestType?.toUpperCase() == 'COURIER';

  factory RequestContent.fromJson(Map<String, dynamic> json) {
    return RequestContent(
      id: json['id'] as int?,
      motorBiker: json['motorBiker'] != null
          ? MotorBiker.fromJson(json['motorBiker'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? Client.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      requestType: _fromJsonString(json['requestType']),
      requestedTime: _fromJsonString(json['requestedTime']),
      createdAt: _fromJsonString(json['createdAt']),
      updatedAt: _fromJsonString(json['updatedAt']),
      originLocation: LocationInfo.fromDynamic(json['originLocation']),
      checkpoints: _parseCheckpoints(json['checkpoints']),
      destinationLocation: _fromJsonString(json['destinationLocation']),
      status: _fromJsonString(json['status']),
      driverId: json['driverId'] as int?,
      driverName: _fromJsonString(json['driverName']),
      driverPhone: _fromJsonString(json['driverPhone']),
      priorityLevel: json['priorityLevel'] as int?,
      manualDispatch: json['manualDispatch'] as bool?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      actualFare: (json['actualFare'] as num?)?.toDouble(),
      pickupTime: _fromJsonString(json['pickupTime']),
      dropoffTime: _fromJsonString(json['dropoffTime']),
      cancelledBy: _fromJsonString(json['cancelledBy']),
      cancellationReason: _fromJsonString(json['cancellationReason']),
      cancelledAt: _fromJsonString(json['cancelledAt']),
      courierFrom: json['courierFrom'] != null
          ? CourierLocation.fromJson(json['courierFrom'] as Map<String, dynamic>)
          : null,
      courierTo: json['courierTo'] != null
          ? CourierLocation.fromJson(json['courierTo'] as Map<String, dynamic>)
          : null,
      courierCheckpoints: _parseCourierCheckpoints(json['courierCheckpoints']),
      packageDescription: _fromJsonString(json['packageDescription']),
      packageWeight: _fromJsonString(json['packageWeight']),
      packageDimensions: _fromJsonString(json['packageDimensions']),
      declaredValue: (json['declaredValue'] as num?)?.toDouble(),
      specialInstructions: _fromJsonString(json['specialInstructions']),
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  static List<Checkpoint> _parseCheckpoints(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) => Checkpoint.fromJson(item))
        .toList();
  }

  static List<CourierCheckpoint> _parseCourierCheckpoints(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .whereType<Map<String, dynamic>>()
        .map((item) => CourierCheckpoint.fromJson(item))
        .toList();
  }

  // DateTime parsers
  DateTime? get requestedDateTime => requestedTime != null
      ? DateTime.tryParse(requestedTime!)
      : null;

  DateTime? get createdDateTime => createdAt != null
      ? DateTime.tryParse(createdAt!)
      : null;

  DateTime? get updatedDateTime => updatedAt != null
      ? DateTime.tryParse(updatedAt!)
      : null;

  DateTime? get pickupDateTime => pickupTime != null
      ? DateTime.tryParse(pickupTime!)
      : null;

  DateTime? get dropoffDateTime => dropoffTime != null
      ? DateTime.tryParse(dropoffTime!)
      : null;

  DateTime? get cancelledDateTime => cancelledAt != null
      ? DateTime.tryParse(cancelledAt!)
      : null;

  /// Whether this request was cancelled
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';

  /// Origin location name as a plain string
  String get originName => originLocation?.name ?? '';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    if (motorBiker != null) {
      dataMap['motorBiker'] = motorBiker!.toJson();
    }
    if (client != null) {
      dataMap['client'] = client!.toJson();
    }
    dataMap['requestType'] = requestType;
    dataMap['requestedTime'] = requestedTime;
    dataMap['createdAt'] = createdAt;
    dataMap['updatedAt'] = updatedAt;
    if (originLocation != null) {
      dataMap['originLocation'] = originLocation!.toJson();
    }
    if (checkpoints.isNotEmpty) {
      dataMap['checkpoints'] = checkpoints.map((c) => c.toJson()).toList();
    }
    dataMap['destinationLocation'] = destinationLocation;
    dataMap['status'] = status;
    dataMap['driverId'] = driverId;
    dataMap['driverName'] = driverName;
    dataMap['driverPhone'] = driverPhone;
    dataMap['priorityLevel'] = priorityLevel;
    dataMap['manualDispatch'] = manualDispatch;
    if (distanceKm != null) dataMap['distanceKm'] = distanceKm;
    if (actualFare != null) dataMap['actualFare'] = actualFare;
    if (pickupTime != null) dataMap['pickupTime'] = pickupTime;
    if (dropoffTime != null) dataMap['dropoffTime'] = dropoffTime;
    if (cancelledBy != null) dataMap['cancelledBy'] = cancelledBy;
    if (cancellationReason != null) dataMap['cancellationReason'] = cancellationReason;
    if (cancelledAt != null) dataMap['cancelledAt'] = cancelledAt;
    if (courierFrom != null) dataMap['courierFrom'] = courierFrom!.toJson();
    if (courierTo != null) dataMap['courierTo'] = courierTo!.toJson();
    if (courierCheckpoints.isNotEmpty) {
      dataMap['courierCheckpoints'] = courierCheckpoints.map((c) => c.toJson()).toList();
    }
    if (packageDescription != null) dataMap['packageDescription'] = packageDescription;
    if (packageWeight != null) dataMap['packageWeight'] = packageWeight;
    if (packageDimensions != null) dataMap['packageDimensions'] = packageDimensions;
    if (declaredValue != null) dataMap['declaredValue'] = declaredValue;
    if (specialInstructions != null) dataMap['specialInstructions'] = specialInstructions;
    return dataMap;
  }

  @override
  String toString() => 'RequestContent(id: $id, status: $status, requestType: $requestType, driverName: $driverName)';
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

class Client {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;

  const Client({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      fname: _fromJsonString(json['fname']),
      lname: _fromJsonString(json['lname']),
      phone: _fromJsonString(json['phone']),
      status: _fromJsonString(json['status']),
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  String? get fullName {
    if (fname == null && lname == null) return null;
    return '${fname ?? ''} ${lname ?? ''}'.trim();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    dataMap['fname'] = fname;
    dataMap['lname'] = lname;
    dataMap['phone'] = phone;
    dataMap['status'] = status;
    return dataMap;
  }

  @override
  String toString() => 'Client(id: $id, fullName: $fullName, phone: $phone, status: $status)';
}