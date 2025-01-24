// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'register_client_bloc.dart';

class RegisterClientEvent extends Equatable {
  const RegisterClientEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends RegisterClientEvent {}

class HandleRegisterClientInformation extends RegisterClientEvent {
  String phone;
  String deviceToken;
  String countryCode;
  HandleRegisterClientInformation({
    required this.phone,
    required this.deviceToken,
    required this.countryCode
  });
}
