part of 'update_sent_request_status_bloc.dart';

class UpdateSentRequestStatusEvent extends Equatable {
  const UpdateSentRequestStatusEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends UpdateSentRequestStatusEvent {}

class HandleUpdateStatus extends UpdateSentRequestStatusEvent {
  String status;
  String requestId;
  HandleUpdateStatus({required this.requestId, required this.status});
}
