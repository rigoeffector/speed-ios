import 'package:bloc/bloc.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:equatable/equatable.dart';

import '../../../model/my.requests.model.dart';

part 'update_sent_request_status_event.dart';
part 'update_sent_request_status_state.dart';

class UpdateSentRequestStatusBloc
    extends Bloc<UpdateSentRequestStatusEvent, UpdateSentRequestStatusState> {
  AuthService sentRequestsService;
  UpdateSentRequestStatusBloc(
      UpdateSentRequestStatusState updateSentRequestStatusState,
      this.sentRequestsService)
      : super(updateSentRequestStatusState) {
    on<UpdateSentRequestStatusEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(UpdateSentRequestStatusInitial());
      } else if (event is HandleUpdateStatus) {
        emit(UpdateSentRequestStatusLaoding());
        MyRequestsModel updateSentRequestModel;
        updateSentRequestModel = await sentRequestsService
            .updateSentRequestStatus(event.requestId, event.status);
        if (updateSentRequestModel.success) {
          emit(UpdateSentRequestStatusSuccess(
              updateSentRequestModel: updateSentRequestModel));
        } else {
          emit(UpdateSentRequestStatusError(
              message: updateSentRequestModel.message.toString()));
        }
      }
    });
  }
}
