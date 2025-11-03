// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'register_client_bloc.dart';

abstract class RegisterClientState extends Equatable {
  const RegisterClientState();

  @override
  List<Object?> get props => [];
}

class RegisterClientInitial extends RegisterClientState {
  const RegisterClientInitial();
}

class RegisterClientLoading extends RegisterClientState {
  const RegisterClientLoading();
}

class RegisterClientSuccess extends RegisterClientState {
  final RegisterClientModel registerClientModel;

  const RegisterClientSuccess({
    required this.registerClientModel,
  });

  @override
  List<Object?> get props => [registerClientModel];

  @override
  String toString() {
    return 'RegisterClientSuccess(data: ${registerClientModel.data})';
  }
}

class RegisterClientError extends RegisterClientState {
  final String message;
  final RegisterClientModel registerClientModel;

  const RegisterClientError({
    required this.message,
    required this.registerClientModel,
  });

  @override
  List<Object?> get props => [message, registerClientModel];

  @override
  String toString() {
    return 'RegisterClientError(message: $message)';
  }
}