// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'register_client_bloc.dart';

class RegisterClientState extends Equatable {
  const RegisterClientState();

  @override
  List<Object> get props => [];
}

class RegisterClientInitial extends RegisterClientState {}

class RegisterClientLoading extends RegisterClientState {}

class RegisterClientSuccess extends RegisterClientState {
  RegisterClientModel registerClientModel;
  RegisterClientSuccess({
    required this.registerClientModel,
  });
}

class RegisterClientError extends RegisterClientState {
  String message;
   RegisterClientModel registerClientModel;
  RegisterClientError({
    required this.message,
    required this.registerClientModel,
  });
}
