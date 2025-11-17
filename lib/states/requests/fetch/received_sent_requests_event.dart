part of 'received_sent_requests_bloc.dart';

abstract class ReceivedSentRequestsEvent extends Equatable {
  const ReceivedSentRequestsEvent();

  @override
  List<Object?> get props => [];
}

class HandleFetchRequests extends ReceivedSentRequestsEvent {
  final String userId;

  const HandleFetchRequests({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ResetReceivedSentRequestsEvent extends ReceivedSentRequestsEvent {
  const ResetReceivedSentRequestsEvent();
}