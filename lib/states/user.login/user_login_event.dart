// ignore_for_file: must_be_immutable

part of 'user_login_bloc.dart';

abstract class UserLoginEvent extends Equatable {
  const UserLoginEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends UserLoginEvent {}

class HandleUSerLogin extends UserLoginEvent {
  String email;
  String password;

  HandleUSerLogin({required this.email, required this.password});
}
