import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import '../../model/verify.otp.model.dart';
part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final AuthService authService;

  VerifyOtpBloc(VerifyOtpState initialState, this.authService)
      : super(initialState) {
    on<VerifyOtpEvent>((event, emit) async {
      if (event is StartVerifyOtpEvent) {
        print('VerifyOtpBloc: Starting OTP verification process');
        emit(VerifyOtpInitial());
      } else if (event is HandleVerifyOtp) {
        print(
            'VerifyOtpBloc: Handling OTP verification for phone: ${event.phone}');
        emit(VerifyOtpLoading());
        try {
          print(
              'VerifyOtpBloc: Calling postVerifyOtp API with phone: ${event.phone}, otp: ${event.otp.replaceAll(RegExp(r'.'), '*')}');
          VerifyOtpModel verifyOtpModel = await authService.postVerifyOtp(
            event.phone,
            event.otp,
          );
          print(
              'VerifyOtpBloc: postVerifyOtp response: ${verifyOtpModel.toJson()}');
          if (verifyOtpModel.success) {
            print('VerifyOtpBloc: OTP verification successful');
            emit(VerifyOtpSuccess(verifyOtpModel: verifyOtpModel));
          } else {
            print(
                'VerifyOtpBloc: OTP verification failed: ${verifyOtpModel.message}');
            emit(VerifyOtpError(
              message: verifyOtpModel.message ?? 'Verification failed',
              verifyOtpModel: verifyOtpModel,
            ));
          }
        } catch (e) {
          print('VerifyOtpBloc: Error during OTP verification: $e');
          emit(VerifyOtpError(
            message: e.toString(),
            verifyOtpModel: VerifyOtpModel(
              success: false,
              message: e.toString(),
            ),
          ));
        }
      } else if (event is HandleResendOtp) {
        print('VerifyOtpBloc: Handling OTP resend for phone: ${event.phone}');
        emit(ResendOtpLoading());
        try {
          print(
              'VerifyOtpBloc: Calling postResendOtp API with phone: ${event.phone}');
          // Assuming you have a resend OTP endpoint
          VerifyOtpModel resendOtpModel = await authService.postResendOtp(
            event.phone,
          );
          print(
              'VerifyOtpBloc: postResendOtp response: ${resendOtpModel.toJson()}');
          if (resendOtpModel.success) {
            print('VerifyOtpBloc: OTP resend successful');
            emit(ResendOtpSuccess(
              message: resendOtpModel.message ?? 'OTP sent successfully',
            ));
          } else {
            print(
                'VerifyOtpBloc: OTP resend failed: ${resendOtpModel.message}');
            emit(ResendOtpError(
              message: resendOtpModel.message ?? 'Failed to resend OTP',
            ));
          }
        } catch (e) {
          print('VerifyOtpBloc: Error during OTP resend: $e');
          emit(ResendOtpError(
            message: e.toString(),
          ));
        }
      }
    });
  }
}
