// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'verify_otp_bloc.dart';

abstract class VerifyOtpState extends Equatable {
  const VerifyOtpState();

  @override
  List<Object?> get props => [];
}

class VerifyOtpInitial extends VerifyOtpState {}

class VerifyOtpLoading extends VerifyOtpState {}

class VerifyOtpSuccess extends VerifyOtpState {
  final VerifyOtpModel verifyOtpModel;

  const VerifyOtpSuccess({
    required this.verifyOtpModel,
  });

  @override
  List<Object?> get props => [verifyOtpModel];
}

class VerifyOtpError extends VerifyOtpState {
  final String message;
  final VerifyOtpModel verifyOtpModel;

  const VerifyOtpError({
    required this.message,
    required this.verifyOtpModel,
  });

  @override
  List<Object?> get props => [message, verifyOtpModel];
}

class ResendOtpLoading extends VerifyOtpState {}

class ResendOtpSuccess extends VerifyOtpState {
  final String message;

  const ResendOtpSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class ResendOtpError extends VerifyOtpState {
  final String message;

  const ResendOtpError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}