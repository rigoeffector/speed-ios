part of 'received_sent_requests_bloc.dart';

class ReceivedSentRequestsEvent extends Equatable {
  const ReceivedSentRequestsEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends ReceivedSentRequestsEvent {}

class HandleFetchRequests extends ReceivedSentRequestsEvent {
  String userId;
  HandleFetchRequests({required this.userId});
}
