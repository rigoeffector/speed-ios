// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'register_client_bloc.dart';

abstract class RegisterClientEvent extends Equatable {
  const RegisterClientEvent();

  @override
  List<Object?> get props => [];
}

class StartEvent extends RegisterClientEvent {
  const StartEvent();
}

class HandleRegisterClientInformation extends RegisterClientEvent {
  final String phone;
  final String deviceToken;
  final String countryCode;

  const HandleRegisterClientInformation({
    required this.phone,
    required this.deviceToken,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [phone, deviceToken, countryCode];

  @override
  String toString() {
    return 'HandleRegisterClientInformation(phone: $phone, deviceToken: $deviceToken, countryCode: $countryCode)';
  }
}