// ignore_for_file: must_be_immutable

part of 'received_sent_requests_bloc.dart';

class ReceivedSentRequestsState extends Equatable {
  const ReceivedSentRequestsState();

  @override
  List<Object> get props => [];
}

class ReceivedSentRequestsInitial extends ReceivedSentRequestsState {}

class ReceivedSentRequestsLoading extends ReceivedSentRequestsState {}

class ReceivedSentRequestsSuccess extends ReceivedSentRequestsState {
  UserSentRequestsModel userSentRequestsModel;
  ReceivedSentRequestsSuccess({required this.userSentRequestsModel});
}

class ReceivedSentRequestsError extends ReceivedSentRequestsState {
  String message;
  ReceivedSentRequestsError({required this.message});
}
