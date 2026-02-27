class AvailableDriverOnMapModel {
  final String message;
  final bool success;
  final NearbyDriversData data;

  const AvailableDriverOnMapModel({
    required this.message,
    required this.success,
    required this.data,
  });

  factory AvailableDriverOnMapModel.fromJson(Map<String, dynamic> json) {
    return AvailableDriverOnMapModel(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      data: NearbyDriversData.fromJson(
          json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'data': data.toJson(),
    };
  }

  // Convenient getters
  bool get hasDrivers => success && data.isNotEmpty;
  List<NearbyDriver> get onlineDrivers => data.onlineDrivers;
  NearbyDriver? get closestDriver => data.closestDriver;
  bool get hasMoreDrivers => data.hasMore;
  int get driverCount => data.count;
}

/// Data container with drivers list and search metadata
class NearbyDriversData {
  final List<NearbyDriver> drivers;
  final int count;
  final SearchCenter searchCenter;
  final double radiusKm;
  final bool hasMore;

  const NearbyDriversData({
    required this.drivers,
    required this.count,
    required this.searchCenter,
    required this.radiusKm,
    required this.hasMore,
  });

  factory NearbyDriversData.fromJson(Map<String, dynamic> json) {
    return NearbyDriversData(
      drivers: _parseDrivers(json['drivers']),
      count: json['count'] as int? ?? 0,
      searchCenter: SearchCenter.fromJson(
          json['searchCenter'] as Map<String, dynamic>? ?? {}),
      radiusKm: _toDouble(json['radiusKm']) ?? 0.0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  static List<NearbyDriver> _parseDrivers(dynamic driversJson) {
    if (driversJson == null || driversJson is! List) {
      return <NearbyDriver>[];
    }

    return driversJson
        .where((item) => item is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .map((item) {
          try {
            return NearbyDriver.fromJson(item);
          } catch (e) {
            print('Error parsing nearby driver: $e');
            return null;
          }
        })
        .whereType<NearbyDriver>()
        .toList();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'drivers': drivers.map((v) => v.toJson()).toList(),
      'count': count,
      'searchCenter': searchCenter.toJson(),
      'radiusKm': radiusKm,
      'hasMore': hasMore,
    };
  }

  bool get isEmpty => drivers.isEmpty;
  bool get isNotEmpty => drivers.isNotEmpty;
  List<NearbyDriver> get onlineDrivers =>
      drivers.where((d) => d.isOnline).toList();
  NearbyDriver? get closestDriver => drivers.isEmpty ? null : drivers.first;
}

/// Individual nearby driver model
class NearbyDriver {
  final int id;
  final int motorBikerId;
  final String motorBikerName;
  final String motorBikerPhone;
  final String motorBikerPlate;
  final double latitude;
  final double longitude;
  final String status;
  final String vehicleType;
  final double rating;
  final double distanceKm;
  final String currentLocationName;

  const NearbyDriver({
    required this.id,
    required this.motorBikerId,
    required this.motorBikerName,
    required this.motorBikerPhone,
    required this.motorBikerPlate,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.vehicleType,
    required this.rating,
    required this.distanceKm,
    required this.currentLocationName,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      id: json['id'] as int,
      motorBikerId: json['motorBikerId'] as int,
      motorBikerName: json['motorBikerName'] as String? ?? '',
      motorBikerPhone: json['motorBikerPhone'] as String? ?? '',
      motorBikerPlate: json['motorBikerPlate'] as String? ?? '',
      latitude: _toDouble(json['latitude']) ?? 0.0,
      longitude: _toDouble(json['longitude']) ?? 0.0,
      status: json['status'] as String? ?? 'OFFLINE',
      vehicleType: json['vehicleType'] as String? ?? 'UNKNOWN',
      rating: _toDouble(json['rating']) ?? 0.0,
      distanceKm: _toDouble(json['distanceKm']) ?? 0.0,
      currentLocationName: json['currentLocationName'] as String? ?? '',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motorBikerId': motorBikerId,
      'motorBikerName': motorBikerName,
      'motorBikerPhone': motorBikerPhone,
      'motorBikerPlate': motorBikerPlate,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'vehicleType': vehicleType,
      'rating': rating,
      'distanceKm': distanceKm,
      'currentLocationName': currentLocationName,
    };
  }

  // Convenient getters
  bool get isOnline => status.toUpperCase() == 'ONLINE';
  bool get isOffline => status.toUpperCase() == 'OFFLINE';
  bool get isBusy => status.toUpperCase() == 'BUSY';
  bool get hasRating => rating > 0.0;

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  String get formattedRating => rating.toStringAsFixed(1);

  String get displayName =>
      motorBikerName.isNotEmpty ? motorBikerName : 'Driver #$motorBikerId';

  bool get isRide => vehicleType.toUpperCase() == 'RIDE';
  bool get isDelivery => vehicleType.toUpperCase() == 'DELIVERY';
}

/// Search center coordinates
class SearchCenter {
  final double latitude;
  final double longitude;

  const SearchCenter({
    required this.latitude,
    required this.longitude,
  });

  factory SearchCenter.fromJson(Map<String, dynamic> json) {
    return SearchCenter(
      latitude: _toDouble(json['latitude']) ?? 0.0,
      longitude: _toDouble(json['longitude']) ?? 0.0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}