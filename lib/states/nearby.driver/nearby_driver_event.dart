// ignore_for_file: must_be_immutable

part of 'nearby_driver_bloc.dart';

abstract class NearbyDriverEvent extends Equatable {
  const NearbyDriverEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends NearbyDriverEvent {}

class HandleNearbyDriverInformation extends NearbyDriverEvent {
  String latitude;
  String longitude;
  String radius;
  String paymentMethod;
  HandleNearbyDriverInformation({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.paymentMethod,
  });
}
