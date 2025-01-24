// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'update_client_bloc.dart';

class UpdateClientState extends Equatable {
  const UpdateClientState();

  @override
  List<Object> get props => [];
}

class UpdateClientInitial extends UpdateClientState {}

class UpdateClientLoading extends UpdateClientState {}

class UpdateClientSuccess extends UpdateClientState {
  UpdateClientInfoModel updateClientInfoModel;
  UpdateClientSuccess({
    required this.updateClientInfoModel,
  });
}

class UpdateClientError extends UpdateClientState {
  String message;
  UpdateClientError({
    required this.message,
  });
}
