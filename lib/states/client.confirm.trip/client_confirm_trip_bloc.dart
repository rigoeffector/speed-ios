import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/trip.service.dart';
import 'package:speed_ios/model/trip/confirm.trip.model.dart';

part 'client_confirm_trip_event.dart';
part 'client_confirm_trip_state.dart';

class ClientConfirmTripBloc
    extends Bloc<ClientConfirmTripEvent, ClientConfirmTripState> {
  TripService tripService;

  ClientConfirmTripBloc(
    ClientConfirmTripState clientConfirmTripState,
    this.tripService,
  ) : super(clientConfirmTripState) {
    on<ClientConfirmTripEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(ClientConfirmTripInitial());
      } else {
        if (event is HandleConfirmTrip) {
          emit(ClientConfirmTripLoading());
          ConfrimTripModel confrimTripModel;
          confrimTripModel = await tripService.fetchCarCategories(
              event.clientId,
              event.tripType,
              event.price,
              event.paymenyMode,
              event.source,
              event.destination,
              event.sLatitude,
              event.sLongitude,
              event.dLatitude,
              event.dLongitude);

          if (confrimTripModel.status) {
            emit(ClientConfirmTripSuccess(confrimTripModel: confrimTripModel));
          } else {
            emit(ClientConfirmTripError(
                message: confrimTripModel.message.toString()));
          }
        }
      }
    });
  }
}
