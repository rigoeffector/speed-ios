// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'verify_otp_bloc.dart';

abstract class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

class StartVerifyOtpEvent extends VerifyOtpEvent {}

class HandleVerifyOtp extends VerifyOtpEvent {
  final String phone;
  final String otp;
  final String? referralCode;

  const HandleVerifyOtp({
    required this.phone,
    required this.otp,
    this.referralCode,
  });

  @override
  List<Object?> get props => [phone, otp, referralCode];
}

class HandleResendOtp extends VerifyOtpEvent {
  final String phone;

  const HandleResendOtp({
    required this.phone,
  });

  @override
  List<Object?> get props => [phone];
}

/// Used by the standalone "Add referral code" screen, for clients
/// who skipped entering a referral code during OTP verification.
class HandleAddReferralCode extends VerifyOtpEvent {
  final String clientId;
  final String referralCode;

  const HandleAddReferralCode({
    required this.clientId,
    required this.referralCode,
  });

  @override
  List<Object?> get props => [clientId, referralCode];
}

/// Resets the bloc back to VerifyOtpInitial, useful when leaving
/// the referral code screen or re-entering the OTP flow.
class ResetVerifyOtpState extends VerifyOtpEvent {}