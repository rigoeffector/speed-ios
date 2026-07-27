import 'package:bloc/bloc.dart';
import 'package:speed_ios/model/my.requests.model.dart';
import 'package:equatable/equatable.dart';

import '../../api/auth.service.dart';

part 'create_request_event.dart';
part 'create_request_state.dart';

class CreateRequestBloc extends Bloc<CreateRequestEvent, CreateRequestState> {
  AuthService requestsRepository;

 

  CreateRequestBloc(CreateRequestState createRequestState, this.requestsRepository)
      : super(createRequestState) {
    on<CreateRequestEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(CreateRequestInitial());
      } else {
        MyRequestsModel myRequestsModel;
        if (event is HandleCreateRequest) {
          emit(CreateRequestLoading());
          myRequestsModel = await requestsRepository.postCLientREquest(
              event.requestBody, requestType: event.requestType);
          if (myRequestsModel.success) {
            emit(CreateRequestSuccess(
                myRequestsModel: myRequestsModel));
          } else {
            emit(CreateRequestError(
                message: myRequestsModel.message.toString(), myRequestsModel: myRequestsModel));
          }
        }
      }
    });
  }
}
