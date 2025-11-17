part of 'received_sent_requests_bloc.dart';

abstract class ReceivedSentRequestsState extends Equatable {
  const ReceivedSentRequestsState();

  @override
  List<Object?> get props => [];
}

class ReceivedSentRequestsInitial extends ReceivedSentRequestsState {
  const ReceivedSentRequestsInitial();
}

class ReceivedSentRequestsLoading extends ReceivedSentRequestsState {
  const ReceivedSentRequestsLoading();
}

class ReceivedSentRequestsSuccess extends ReceivedSentRequestsState {
  final UserSentRequestsModel userSentRequestsModel;

  const ReceivedSentRequestsSuccess({required this.userSentRequestsModel});

  @override
  List<Object?> get props => [userSentRequestsModel];
}

class ReceivedSentRequestsError extends ReceivedSentRequestsState {
  final String message;

  const ReceivedSentRequestsError({required this.message});

  @override
  List<Object?> get props => [message];
}