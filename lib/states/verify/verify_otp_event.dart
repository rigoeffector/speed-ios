// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'verify_otp_bloc.dart';

abstract class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object> get props => [];
}

class StartVerifyOtpEvent extends VerifyOtpEvent {}

class HandleVerifyOtp extends VerifyOtpEvent {
  final String phone;
  final String otp;

  const HandleVerifyOtp({
    required this.phone,
    required this.otp,
  });

  @override
  List<Object> get props => [phone, otp];
}

class HandleResendOtp extends VerifyOtpEvent {
  final String phone;

  const HandleResendOtp({
    required this.phone,
  });

  @override
  List<Object> get props => [phone];
}