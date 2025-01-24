import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/auth/register.client.model.dart';

part 'register_client_event.dart';
part 'register_client_state.dart';

class RegisterClientBloc
    extends Bloc<RegisterClientEvent, RegisterClientState> {
  AuthService authService;
  RegisterClientBloc(RegisterClientState registerClientState, this.authService)
      : super(registerClientState) {
    on<RegisterClientEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(RegisterClientInitial());
      } else {
        if (event is HandleRegisterClientInformation) {
          emit(RegisterClientLoading());
          RegisterClientModel registerClientModel;
          registerClientModel = await authService.postRegisterClientInfo(
              event.phone, event.deviceToken, event.countryCode);

          print(registerClientModel);

          if (registerClientModel.success) {
            emit(RegisterClientSuccess(
                registerClientModel: registerClientModel));
          } else {
            emit(RegisterClientError(
                message: registerClientModel.message.toString(),
                registerClientModel: registerClientModel));
          }
        }
      }
    });
  }
}
