// ignore_for_file: must_be_immutable

part of 'user_login_bloc.dart';

abstract class UserLoginState extends Equatable {
  const UserLoginState();

  @override
  List<Object> get props => [];
}

class UserLoginInitial extends UserLoginState {}

class UserLoginLoading extends UserLoginState {}

class UserLoginSuccess extends UserLoginState {
  UserLoginModel userLoginModel;
  UserLoginSuccess({
    required this.userLoginModel,
  });
}

class UserLoginError extends UserLoginState {
  String message;
  UserLoginError({
    required this.message,
  });
}
