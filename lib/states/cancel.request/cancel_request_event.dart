// ignore_for_file: must_be_immutable

part of 'cancel_request_bloc.dart';

abstract class CancelRequestEvent extends Equatable {
  const CancelRequestEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends CancelRequestEvent {}

class HandleCancelRequestInformation extends CancelRequestEvent {
  String requestId;
  String feedback;
  HandleCancelRequestInformation({
    required this.requestId, required this.feedback
  });
}
