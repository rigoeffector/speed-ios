// ignore_for_file: must_be_immutable

part of 'available_driver_location_bloc.dart';

abstract class AvailableDriverLocationState extends Equatable {
  const AvailableDriverLocationState();
  
  @override
  List<Object> get props => [];
}
class AvailableDriverLocationInitial extends AvailableDriverLocationState {}


class AvailableDriverLocationLoading extends AvailableDriverLocationState {}


class AvailableDriverLocationSuccess extends AvailableDriverLocationState {
  AvailableDriverOnMapModel availableDriverOnMapModel;
  AvailableDriverLocationSuccess({
    required this.availableDriverOnMapModel,
  });
}

class AvailableDriverLocationError extends AvailableDriverLocationState {
  String message;
  AvailableDriverLocationError({
    required this.message,
  });
}
