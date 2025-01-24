// ignore_for_file: prefer_const_constructors_in_immutables

part of 'create_request_bloc.dart';

class CreateRequestEvent extends Equatable {
  const CreateRequestEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends CreateRequestEvent {}

// Event to handle the creation of a request
class HandleCreateRequest extends CreateRequestEvent {
  final int motorBikerId;
  final int clientId;
  final String requestType;
  final DateTime requestedTime;
  final String originLocation;
  final String destinationLocation;
  final String status;

  HandleCreateRequest({
    required this.motorBikerId,
    required this.clientId,
    required this.requestType,
    required this.requestedTime,
    required this.originLocation,
    required this.destinationLocation,
    required this.status,
  });

  // @override
  // List<Object> get props => [
  //       motorBikerId,
  //       clientId,
  //       requestType,
  //       requestedTime,
  //       originLocation,
  //       destinationLocation,
  //       status,
  //     ];
}
