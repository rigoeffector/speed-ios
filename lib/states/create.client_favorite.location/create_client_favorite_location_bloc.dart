import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../api/location.service.dart';
import '../../model/client.location.model.dart';

part 'create_client_favorite_location_event.dart';
part 'create_client_favorite_location_state.dart';

class CreateClientFavoriteLocationBloc extends Bloc<
    CreateClientFavoriteLocationEvent, CreateClientFavoriteLocationState> {
  LocationService locationService;

  CreateClientFavoriteLocationBloc(
      CreateClientFavoriteLocationState clientFavoriteLocationState,
      this.locationService)
      : super(clientFavoriteLocationState) {
    on<CreateClientFavoriteLocationEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(CreateClientFavoriteLocationInitial());
      } else {
        if (event is HandleCreateLocationEvent) {
          emit(CreateClientFavoriteLocationLoading());
          CreateClientLocationModel model;
          model = await locationService.createClientFavoriteLocation(
              event.latitude,
              event.longitude,
              event.clientId,
              event.title,
              event.address,
              event.phone);
          if (model.status) {
            emit(CreateClientFavoriteLocationSuccess(model: model));
          } else {
            emit(CreateClientFavoriteLocationError(
                message: model.message.toString()));
          }
        }
      }
    });
  }
}
