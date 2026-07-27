class ActiveRequestModel {
  final bool success;
  final String message;
  final ActiveRequestData? data;

  ActiveRequestModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory ActiveRequestModel.fromJson(Map<String, dynamic> json) {
    return ActiveRequestModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? ActiveRequestData.fromJson(json['data']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class ActiveRequestData {
  final int? id;
  final String? requestType;
  final String? originLocation;
  final double? originLatitude;
  final double? originLongitude;
  final String? destinationLocation;
  final List<CheckpointInfo>? checkpoints;
  final String? status;
  final String? requestedTime;
  final String? createdAt;
  final String? updatedAt;
  
  // Driver information
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  
  // Dispatch information
  final int? priorityLevel;
  final bool? isManualDispatch;
  
  // Pricing and distance
  final double? estimatedFare;
  final double? actualFare;
  final double? distanceKm;
  
  // Timestamps
  final String? acceptedAt;
  final String? pickupTime;
  final String? dropoffTime;
  
  // Additional info
  final String? notes;
  final String? motorType;
  
  // Cancellation info
  final String? cancelledBy;
  final String? cancellationReason;
  final String? cancelledAt;
  
  // Related objects
  final MotorBikerInfo? motorBiker;
  final ClientInfo? client;

  ActiveRequestData({
    this.id,
    this.requestType,
    this.originLocation,
    this.originLatitude,
    this.originLongitude,
    this.destinationLocation,
    this.checkpoints,
    this.status,
    this.requestedTime,
    this.createdAt,
    this.updatedAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.priorityLevel,
    this.isManualDispatch,
    this.estimatedFare,
    this.actualFare,
    this.distanceKm,
    this.acceptedAt,
    this.pickupTime,
    this.dropoffTime,
    this.notes,
    this.motorType,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    this.motorBiker,
    this.client,
  });

  /// Safely extract a location name from a field that may be a String or a Map.
  static String? _parseLocationName(dynamic value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) return value['name'] as String?;
    return null;
  }

  factory ActiveRequestData.fromJson(Map<String, dynamic> json) {
    final rawOrigin = json['originLocation'] ?? json['origin_location'];

    return ActiveRequestData(
      id: json['id'],
      requestType: json['requestType'] ?? json['request_type'],
      originLocation: _parseLocationName(rawOrigin),
      originLatitude: rawOrigin is Map ? (rawOrigin['latitude'] as num?)?.toDouble() : null,
      originLongitude: rawOrigin is Map ? (rawOrigin['longitude'] as num?)?.toDouble() : null,
      destinationLocation: _parseLocationName(json['destinationLocation'] ?? json['destination_location']),
      checkpoints: json['checkpoints'] != null
          ? (json['checkpoints'] as List)
              .map((e) => CheckpointInfo.fromJson(e))
              .toList()
          : null,
      status: json['status'],
      requestedTime: json['requestedTime'] ?? json['requested_time'],
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      driverId: json['driverId'] ?? json['driver_id'],
      driverName: json['driverName'] ?? json['driver_name'],
      driverPhone: json['driverPhone'] ?? json['driver_phone'],
      priorityLevel: json['priorityLevel'] ?? json['priority_level'] ?? 0,
      isManualDispatch: json['manualDispatch'] ?? json['manual_dispatch'] ?? json['isManualDispatch'] ?? false,
      estimatedFare: json['estimatedFare']?.toDouble() ?? json['estimated_fare']?.toDouble(),
      actualFare: json['actualFare']?.toDouble() ?? json['actual_fare']?.toDouble(),
      distanceKm: json['distanceKm']?.toDouble() ?? json['distance_km']?.toDouble(),
      acceptedAt: json['acceptedAt'] ?? json['accepted_at'],
      pickupTime: json['pickupTime'] ?? json['pickup_time'],
      dropoffTime: json['dropoffTime'] ?? json['dropoff_time'],
      notes: json['notes'],
      motorType: json['motorType'] ?? json['motor_type'],
      cancelledBy: json['cancelledBy'] ?? json['cancelled_by'],
      cancellationReason: json['cancellationReason'] ?? json['cancellation_reason'],
      cancelledAt: json['cancelledAt'] ?? json['cancelled_at'],
      motorBiker: json['motorBiker'] != null 
          ? MotorBikerInfo.fromJson(json['motorBiker'])
          : null,
      client: json['client'] != null 
          ? ClientInfo.fromJson(json['client'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestType': requestType,
      'originLocation': originLatitude != null
          ? {'name': originLocation, 'latitude': originLatitude, 'longitude': originLongitude}
          : originLocation,
      'destinationLocation': destinationLocation,
      'checkpoints': checkpoints?.map((c) => c.toJson()).toList(),
      'status': status,
      'requestedTime': requestedTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'priorityLevel': priorityLevel,
      'manualDispatch': isManualDispatch,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'distanceKm': distanceKm,
      'acceptedAt': acceptedAt,
      'pickupTime': pickupTime,
      'dropoffTime': dropoffTime,
      'notes': notes,
      'motorType': motorType,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt,
      'motorBiker': motorBiker?.toJson(),
      'client': client?.toJson(),
    };
  }

  // Helper getter for full driver name
  String get fullDriverName => driverName ?? '${motorBiker?.firstName ?? ''} ${motorBiker?.lastName ?? ''}'.trim();
  
  // Helper getter for driver contact
  String get driverContact => driverPhone ?? motorBiker?.phone ?? 'N/A';
  
  // Helper to check if request is active
  bool get isActive => [
    'PENDING',
    'SEARCHING_DRIVER',
    'APPROVED',
    'ASSIGNED',
    'ACCEPTED',
    'DRIVER_ARRIVING',
    'IN_PROGRESS',
    'ONGOING'
  ].contains(status?.toUpperCase());
  
  // Helper to check if driver is assigned
  bool get hasDriver =>
      (driverId != null && driverId! > 0) || motorBiker != null;
}

class MotorBikerInfo {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? plateNumber;
  final String? chassisNumber;
  final String? vestNumber;
  final String? motorType;
  final String? status;
  final String? deviceToken;
  final bool? speedDriverAccess;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? fullName;

  MotorBikerInfo({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.plateNumber,
    this.chassisNumber,
    this.vestNumber,
    this.motorType,
    this.status,
    this.deviceToken,
    this.speedDriverAccess,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.fullName,
  });

  factory MotorBikerInfo.fromJson(Map<String, dynamic> json) {
    return MotorBikerInfo(
      id: json['id'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      phone: json['phone'],
      plateNumber: json['plateNumber'] ?? json['plate_number'],
      chassisNumber: json['chassisNumber'] ?? json['chassis_number'],
      vestNumber: json['vestNumber'] ?? json['vest_number'],
      motorType: json['motorType'] ?? json['motor_type'],
      status: json['status'],
      deviceToken: json['deviceToken'] ?? json['device_token'],
      speedDriverAccess: json['speedDriverAccess'] ?? json['speed_driver_access'],
      isActive: json['isActive'] ?? json['is_active'],
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      fullName: json['fullName'] ?? json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'plateNumber': plateNumber,
      'chassisNumber': chassisNumber,
      'vestNumber': vestNumber,
      'motorType': motorType,
      'status': status,
      'deviceToken': deviceToken,
      'speedDriverAccess': speedDriverAccess,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'fullName': fullName,
    };
  }

  // Helper getter for display name
  String get displayName => fullName ?? '$firstName $lastName'.trim();
  
  // Helper to check if driver is online
  bool get isOnline => status?.toUpperCase() == 'ONLINE';
}

class ClientInfo {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;

  ClientInfo({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'],
      fname: json['fname'] ?? json['firstName'] ?? json['first_name'],
      lname: json['lname'] ?? json['lastName'] ?? json['last_name'],
      phone: json['phone'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'status': status,
    };
  }

  // Helper getter for full name
  String get fullName => '${fname ?? ''} ${lname ?? ''}'.trim();
  
  // Helper to check if verified
  bool get isVerified => status?.toUpperCase() == 'VERIFIED';
}

class CheckpointInfo {
  final String? name;
  final double? latitude;
  final double? longitude;
  final int? order;

  CheckpointInfo({this.name, this.latitude, this.longitude, this.order});

  factory CheckpointInfo.fromJson(Map<String, dynamic> json) {
    return CheckpointInfo(
      name: json['name'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'order': order,
      };
}
