import 'package:bloc/bloc.dart';
import 'package:speed_ios/controllers/request_controller.dart';
import 'package:speed_ios/model/received.sent.requests.model.dart';
import 'package:equatable/equatable.dart';

part 'received_sent_requests_event.dart';
part 'received_sent_requests_state.dart';

class ReceivedSentRequestsBloc
    extends Bloc<ReceivedSentRequestsEvent, ReceivedSentRequestsState> {
  RequestsRepository requestsRepository;
  ReceivedSentRequestsBloc(ReceivedSentRequestsState receivedSentRequestsState,
      this.requestsRepository)
      : super(receivedSentRequestsState) {
    on<ReceivedSentRequestsEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(ReceivedSentRequestsInitial());
      } else if (event is HandleFetchRequests) {
        emit(ReceivedSentRequestsLoading());
        UserSentRequestsModel userSentRequestsModel =
            await requestsRepository.dispatchingFetchRequest(event.userId);
        if (userSentRequestsModel.success) {
          emit(ReceivedSentRequestsSuccess(
              userSentRequestsModel: userSentRequestsModel));
        } else {
          emit(ReceivedSentRequestsError(
              message: userSentRequestsModel.message.toString()));
        }
      }
    });
  }
}
