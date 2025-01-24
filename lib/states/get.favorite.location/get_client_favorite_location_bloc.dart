import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../api/location.service.dart';
import '../../model/client.favorite.location.model.dart';

part 'get_client_favorite_location_event.dart';
part 'get_client_favorite_location_state.dart';

class GetClientFavoriteLocationBloc extends Bloc<GetClientFavoriteLocationEvent,
    GetClientFavoriteLocationState> {
  LocationService locationService;

  GetClientFavoriteLocationBloc(
      GetClientFavoriteLocationState getClientFavoriteLocationState,
      this.locationService)
      : super(getClientFavoriteLocationState) {
    on<GetClientFavoriteLocationEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(GetClientFavoriteLocationInitial());
      } else {
        if (event is FetchFavoriteLocationEvent) {
          emit(GetClientFavoriteLocationLoading());
          ClientFavoriteLocationModel model;
          model = await locationService.getClientFavoriteLocation(
            event.clientId,
          );
          if (model.status) {
            emit(GetClientFavoriteLocationSuccess(model: model));
          } else {
            emit(GetClientFavoriteLocationError(
                message: model.message.toString()));
          }
        }
      }
    });
  }
}
