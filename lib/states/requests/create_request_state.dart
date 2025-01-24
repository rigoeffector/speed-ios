// ignore_for_file: must_be_immutable, duplicate_ignore

part of 'create_request_bloc.dart';

class CreateRequestState extends Equatable {
  const CreateRequestState();

  @override
  List<Object> get props => [];
}

class CreateRequestInitial extends CreateRequestState {}

class CreateRequestLoading extends CreateRequestState {}

class CreateRequestSuccess extends CreateRequestState {
  MyRequestsModel myRequestsModel;
  CreateRequestSuccess({
    required this.myRequestsModel,
  });
}

class CreateRequestError extends CreateRequestState {
  String message;
  MyRequestsModel myRequestsModel;
  CreateRequestError({
    required this.message,
    required this.myRequestsModel,
  });
}
