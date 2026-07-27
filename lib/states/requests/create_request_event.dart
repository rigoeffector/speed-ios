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
  final Map<String, dynamic> requestBody;
  final String status;
  final String requestType;

  HandleCreateRequest({
    required this.requestBody,
    required this.status,
    this.requestType = 'RIDE',
  });

  @override
  List<Object> get props => [requestBody, status, requestType];
}
