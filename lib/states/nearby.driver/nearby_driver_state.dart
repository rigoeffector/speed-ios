// ignore_for_file: must_be_immutable

part of 'nearby_driver_bloc.dart';

abstract class NearbyDriverState extends Equatable {
  const NearbyDriverState();
  
  @override
  List<Object> get props => [];
}

class NearbyDriverInitial extends NearbyDriverState {}


class NearbyDriverLoading extends NearbyDriverState {}

class NearbyDriverSuccess extends NearbyDriverState {
  NearbyDriverModel nearbyDriverModel;
  NearbyDriverSuccess({
    required this.nearbyDriverModel,
  });
}

class NearbyDriverError extends NearbyDriverState {
  String message;
  NearbyDriverError({
    required this.message,
  });
}
