import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../api/location.service.dart';
import '../../model/available.driver/available.driver.on.map.model.dart';

part 'available_driver_location_event.dart';
part 'available_driver_location_state.dart';

class AvailableDriverLocationBloc
    extends Bloc<AvailableDriverLocationEvent, AvailableDriverLocationState> {
  LocationService locationService;
  AvailableDriverLocationBloc(
      AvailableDriverLocationState availableDriverLocationState,
      this.locationService)
      : super(availableDriverLocationState) {
    on<AvailableDriverLocationEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(AvailableDriverLocationInitial());
      } else {
        if (event is FetchAvailableDriverLocationEvent) {
          emit(AvailableDriverLocationLoading());
          AvailableDriverOnMapModel availableDriverOnMapModel;
          availableDriverOnMapModel =
              await locationService.fetchAvailableDriverLocation();
          if (availableDriverOnMapModel.success) {
            emit(AvailableDriverLocationSuccess(
                availableDriverOnMapModel: availableDriverOnMapModel));
          } else {
            emit(AvailableDriverLocationError(
                message: availableDriverOnMapModel.message.toString()));
          }
        }
      }
    });
  }
}
