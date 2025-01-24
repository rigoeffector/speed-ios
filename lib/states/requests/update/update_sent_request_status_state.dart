// ignore_for_file: must_be_immutable

part of 'update_sent_request_status_bloc.dart';

class UpdateSentRequestStatusState extends Equatable {
  const UpdateSentRequestStatusState();

  @override
  List<Object> get props => [];
}

class UpdateSentRequestStatusInitial extends UpdateSentRequestStatusState {}

class UpdateSentRequestStatusLaoding extends UpdateSentRequestStatusState {}

class UpdateSentRequestStatusSuccess extends UpdateSentRequestStatusState {
  MyRequestsModel updateSentRequestModel;
  UpdateSentRequestStatusSuccess({required this.updateSentRequestModel});
}

class UpdateSentRequestStatusError extends UpdateSentRequestStatusState {
  String message;
  UpdateSentRequestStatusError({required this.message});
}
