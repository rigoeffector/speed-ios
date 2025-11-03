import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/auth/register.client.model.dart';

part 'register_client_event.dart';
part 'register_client_state.dart';

class RegisterClientBloc
    extends Bloc<RegisterClientEvent, RegisterClientState> {
  final AuthService authService;

  RegisterClientBloc(RegisterClientState registerClientState, this.authService)
      : super(registerClientState) {
    on<StartEvent>(_onStartEvent);
    on<HandleRegisterClientInformation>(_onHandleRegisterClientInformation);
  }

  // Handler for StartEvent
  Future<void> _onStartEvent(
    StartEvent event,
    Emitter<RegisterClientState> emit,
  ) async {
    emit(RegisterClientInitial());
  }

  // Handler for HandleRegisterClientInformation
  Future<void> _onHandleRegisterClientInformation(
    HandleRegisterClientInformation event,
    Emitter<RegisterClientState> emit,
  ) async {
    emit(RegisterClientLoading());

    try {
      final RegisterClientModel registerClientModel =
          await authService.postRegisterClientInfo(
        event.phone,
        event.deviceToken,
        event.countryCode,
      );

      print('Registration Response: $registerClientModel');

      if (registerClientModel.success) {
        emit(RegisterClientSuccess(registerClientModel: registerClientModel));
      } else {
        emit(RegisterClientError(
          message: registerClientModel.message ?? 'Registration failed',
          registerClientModel: registerClientModel,
        ));
      }
    } catch (e) {
      print('Registration Error: $e');
      emit(RegisterClientError(
        message: 'An error occurred: ${e.toString()}',
        registerClientModel: RegisterClientModel(
          success: false,
          message: e.toString(),
          data: [],
        ),
      ));
    }
  }
}
