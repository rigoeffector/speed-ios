part of 'available_driver_location_bloc.dart';

abstract class AvailableDriverLocationEvent extends Equatable {
  const AvailableDriverLocationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAvailableDriverLocationEvent
    extends AvailableDriverLocationEvent {
  const InitializeAvailableDriverLocationEvent();
}

class FetchAvailableDriverLocationEvent extends AvailableDriverLocationEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;

  const FetchAvailableDriverLocationEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, limit];
}

class RefreshAvailableDriversEvent extends AvailableDriverLocationEvent {
  const RefreshAvailableDriversEvent();
}

class ExpandSearchRadiusEvent extends AvailableDriverLocationEvent {
  const ExpandSearchRadiusEvent();
}