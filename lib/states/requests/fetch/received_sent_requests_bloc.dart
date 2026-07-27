import 'package:bloc/bloc.dart';
import 'package:speed_ios/controllers/request_controller.dart';
import 'package:equatable/equatable.dart';

import '../../../model/received.sent.requests.model.dart';

part 'received_sent_requests_event.dart';
part 'received_sent_requests_state.dart';

class ReceivedSentRequestsBloc
    extends Bloc<ReceivedSentRequestsEvent, ReceivedSentRequestsState> {
  final RequestsRepository requestsRepository;

  ReceivedSentRequestsBloc({
    required this.requestsRepository,
  }) : super(const ReceivedSentRequestsInitial()) {
    on<HandleFetchRequests>(_onHandleFetchRequests);
    on<ResetReceivedSentRequestsEvent>(_onResetReceivedSentRequests);
  }

  Future<void> _onHandleFetchRequests(
    HandleFetchRequests event,
    Emitter<ReceivedSentRequestsState> emit,
  ) async {
    emit(const ReceivedSentRequestsLoading());

    try {
      final UserSentRequestsModel userSentRequestsModel =
          await requestsRepository.dispatchingFetchRequest(event.userId);

      if (userSentRequestsModel.success) {
        emit(ReceivedSentRequestsSuccess(
          userSentRequestsModel: userSentRequestsModel,
        ));
      } else {
        emit(ReceivedSentRequestsError(
          message: userSentRequestsModel.message ?? 'Failed to fetch requests',
        ));
      }
    } catch (e) {
      emit(ReceivedSentRequestsError(
        message: 'An unexpected error occurred: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResetReceivedSentRequests(
    ResetReceivedSentRequestsEvent event,
    Emitter<ReceivedSentRequestsState> emit,
  ) async {
    emit(const ReceivedSentRequestsInitial());
  }
}