// lib/states/available_driver_location/available_driver_location_state.dart
part of 'available_driver_location_bloc.dart';

abstract class AvailableDriverLocationState extends Equatable {
  const AvailableDriverLocationState();

  @override
  List<Object?> get props => [];
}

class AvailableDriverLocationInitial extends AvailableDriverLocationState {
  const AvailableDriverLocationInitial();
}

class AvailableDriverLocationLoading extends AvailableDriverLocationState {
  final String? message;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const AvailableDriverLocationLoading({
    this.message,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  @override
  List<Object?> get props => [message, latitude, longitude, radiusKm];
}

class AvailableDriverLocationSuccess extends AvailableDriverLocationState {
  final AvailableDriverOnMapModel response;
  final double searchLatitude;
  final double searchLongitude;
  final double radiusKm;
  final DateTime lastUpdated;

  const AvailableDriverLocationSuccess({
    required this.response,
    required this.searchLatitude,
    required this.searchLongitude,
    required this.radiusKm,
    required this.lastUpdated,
  });

  AvailableDriverLocationSuccess copyWith({
    AvailableDriverOnMapModel? response,
    double? searchLatitude,
    double? searchLongitude,
    double? radiusKm,
    DateTime? lastUpdated,
  }) {
    return AvailableDriverLocationSuccess(
      response: response ?? this.response,
      searchLatitude: searchLatitude ?? this.searchLatitude,
      searchLongitude: searchLongitude ?? this.searchLongitude,
      radiusKm: radiusKm ?? this.radiusKm,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Convenient getters
  List<NearbyDriver> get drivers => response.data.drivers;
  int get driversCount => response.driverCount;
  bool get hasDrivers => response.hasDrivers;
  bool get hasMore => response.hasMoreDrivers;
  List<NearbyDriver> get onlineDrivers => response.onlineDrivers;
  NearbyDriver? get closestDriver => response.closestDriver;
  
  // Metadata getters
  SearchCenter get searchCenter => response.data.searchCenter;
  String get message => response.message;
  
  // Time since last update
  Duration get timeSinceUpdate => DateTime.now().difference(lastUpdated);
  bool get isStale => timeSinceUpdate.inMinutes > 2;

  @override
  List<Object?> get props => [
        response,
        searchLatitude,
        searchLongitude,
        radiusKm,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'AvailableDriverLocationSuccess(driversCount: $driversCount, '
        'radiusKm: $radiusKm, hasMore: $hasMore, isStale: $isStale)';
  }
}

class AvailableDriverLocationEmpty extends AvailableDriverLocationState {
  final double searchLatitude;
  final double searchLongitude;
  final double radiusKm;
  final String message;
  final bool canExpandSearch;

  const AvailableDriverLocationEmpty({
    required this.searchLatitude,
    required this.searchLongitude,
    required this.radiusKm,
    required this.message,
    this.canExpandSearch = true,
  });

  @override
  List<Object?> get props => [
        searchLatitude,
        searchLongitude,
        radiusKm,
        message,
        canExpandSearch,
      ];

  @override
  String toString() {
    return 'AvailableDriverLocationEmpty(radiusKm: $radiusKm, '
        'canExpandSearch: $canExpandSearch, message: $message)';
  }
}

class AvailableDriverLocationError extends AvailableDriverLocationState {
  final String message;
  final double? lastSearchLatitude;
  final double? lastSearchLongitude;
  final double? radiusKm;

  const AvailableDriverLocationError({
    required this.message,
    this.lastSearchLatitude,
    this.lastSearchLongitude,
    this.radiusKm,
  });

  bool get canRetry =>
      lastSearchLatitude != null && lastSearchLongitude != null;

  @override
  List<Object?> get props => [
        message,
        lastSearchLatitude,
        lastSearchLongitude,
        radiusKm,
      ];

  @override
  String toString() {
    return 'AvailableDriverLocationError(message: $message, '
        'canRetry: $canRetry)';
  }
}