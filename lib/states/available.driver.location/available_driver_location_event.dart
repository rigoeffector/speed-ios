part of 'available_driver_location_bloc.dart';


abstract class AvailableDriverLocationEvent extends Equatable {
  const AvailableDriverLocationEvent();

  @override
  List<Object> get props => [];
}


class StartEvent extends AvailableDriverLocationEvent {}

class FetchAvailableDriverLocationEvent extends AvailableDriverLocationEvent {}
