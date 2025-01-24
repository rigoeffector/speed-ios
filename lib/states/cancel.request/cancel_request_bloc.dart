import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/cancel.service.dart';

import '../../model/cancel.request/cancel.request.model.dart';

part 'cancel_request_event.dart';
part 'cancel_request_state.dart';

class CancelRequestBloc extends Bloc<CancelRequestEvent, CancelRequestState> {
  CancelService cancelService;
  CancelRequestBloc(CancelRequestState cancelRequestState, this.cancelService)
      : super(cancelRequestState) {
    on<CancelRequestEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(CancelRequestInitial());
      } else {
        if (event is HandleCancelRequestInformation) {
          emit(CancelRequestLoading());
          CancelRequestModel cancelRequestModel;
          cancelRequestModel = await cancelService.postCancelRequestInfo(
              event.requestId, event.feedback);
          if (cancelRequestModel.status) {
            emit(CancelRequestSuccess(cancelRequestModel: cancelRequestModel));
          } else {
            emit(CancelRequestError(
                message: cancelRequestModel.message.toString()));
          }
        }
      }
    });
  }
}
