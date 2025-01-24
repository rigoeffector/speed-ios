// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'client_confirm_trip_bloc.dart';

class ClientConfirmTripState extends Equatable {
  const ClientConfirmTripState();

  @override
  List<Object> get props => [];
}

class ClientConfirmTripInitial extends ClientConfirmTripState {}

class ClientConfirmTripLoading extends ClientConfirmTripState {}

class ClientConfirmTripSuccess extends ClientConfirmTripState {
  ConfrimTripModel confrimTripModel;
  ClientConfirmTripSuccess({
    required this.confrimTripModel,
  });
}

class ClientConfirmTripError extends ClientConfirmTripState {
  String message;
  ClientConfirmTripError({
    required this.message,
  });
}
