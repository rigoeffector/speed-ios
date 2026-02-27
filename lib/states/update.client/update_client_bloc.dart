import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/auth/update.client.model.dart';

part 'update_client_event.dart';
part 'update_client_state.dart';

class UpdateClientBloc extends Bloc<UpdateClientEvent, UpdateClientState> {
  AuthService authService;
  UpdateClientBloc(UpdateClientState updateClientState, this.authService)
      : super(updateClientState) {
    on<UpdateClientEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(UpdateClientInitial());
      } else {
        UpdateClientInfoModel updateClientInfoModel;
        if (event is HandleUpdateClientInformation) {
          emit(UpdateClientLoading());
          updateClientInfoModel = await authService.postUpdateClientInfo(
            event.clientId,
            event.fname,
            event.lname,
            event.deviceToken,
          );
          if (updateClientInfoModel.success) {
            emit(UpdateClientSuccess(
                updateClientInfoModel: updateClientInfoModel));
          } else {
            emit(UpdateClientError(
                message: updateClientInfoModel.message.toString()));
          }
        }
      }
    });
  }
}
