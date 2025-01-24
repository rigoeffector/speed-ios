// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'client_confirm_trip_bloc.dart';

class ClientConfirmTripEvent extends Equatable {
  const ClientConfirmTripEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends ClientConfirmTripEvent {}

class HandleConfirmTrip extends ClientConfirmTripEvent {
  String clientId;
  String tripType;
  String price;
  String paymenyMode;
  String source;
  String destination;
  String sLatitude;
  String sLongitude;
  String dLatitude;
  String dLongitude;
  HandleConfirmTrip({
    required this.clientId,
    required this.tripType,
    required this.price,
    required this.paymenyMode,
    required this.source,
    required this.destination,
    required this.sLatitude,
    required this.sLongitude,
    required this.dLatitude,
    required this.dLongitude,
  });
}
