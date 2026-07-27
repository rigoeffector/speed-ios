import 'package:bloc/bloc.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/update.profile.model.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

part 'update_profile_event.dart';
part 'update_profile_state.dart';

class UpdateProfileBloc extends Bloc<UpdateProfileEvent, UpdateProfileState> {
    AuthService authService;
  UpdateProfileBloc(UpdateProfileState updateProfileState, this.authService) : super(updateProfileState) {
    on<UpdateProfileEvent>((event, emit) async {
       if (event is StartEvent) {
        emit(UpdateProfileInitial());
      } else {
        UpdateProfileModel updateProfileModel;
        if (event is HandleUpdateProfileInformation) {
          emit(UpdateClientLoading());
          updateProfileModel = await authService.postUpdateClientInfoV2(
            event.clientId,
            event.clientName,
            event.photo
          );
          if (updateProfileModel.success) {
            emit(UpdateProfileSuccess(
                updateProfileModel: updateProfileModel));
          } else {
            emit(UpdateProfileError(
                message: updateProfileModel.message.toString()));
          }
        }
      }
    });
  }
}
