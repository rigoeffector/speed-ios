import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/auth/client.profile.model.dart';

part 'client_profile_event.dart';
part 'client_profile_state.dart';

class ClientProfileBloc extends Bloc<ClientProfileEvent, ClientProfileState> {
  AuthService authService;
  ClientProfileBloc(ClientProfileState clientProfileState, this.authService)
      : super(clientProfileState) {
    on<ClientProfileEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(ClientProfileInitial());
      } else {
        ClientProfileModel clientProfileModel;
        if (event is FetchAllClientInformation) {
          emit(ClientProfileLoading());
          clientProfileModel = await authService.fetchingAllClientProfileInfo(
            event.clientId,
          );
          if (clientProfileModel.success) {
            emit(ClientProfileSuccess(clientProfileModel: clientProfileModel));
          } else {
            emit(ClientProfileError(
                message: clientProfileModel.message.toString()));
          }
        }
      }
    });
  }
}
