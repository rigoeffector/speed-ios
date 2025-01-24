import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/location.service.dart';

import '../../model/nearby_driver_model.dart';

part 'nearby_driver_event.dart';
part 'nearby_driver_state.dart';

class NearbyDriverBloc extends Bloc<NearbyDriverEvent, NearbyDriverState> {
  LocationService locationService;
  NearbyDriverBloc(NearbyDriverState nearbyDriverState, this.locationService)
      : super(nearbyDriverState) {
    on<NearbyDriverEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(NearbyDriverInitial());
      } else {
        if (event is HandleNearbyDriverInformation) {
          emit(NearbyDriverLoading());
          NearbyDriverModel nearbyDriverModel;
          nearbyDriverModel =
              await locationService.fetchNearbyDriveerLocationInfo(
                  event.latitude,
                  event.longitude,
                  event.radius,
                  event.paymentMethod);
          if (nearbyDriverModel.success) {
            emit(NearbyDriverSuccess(nearbyDriverModel: nearbyDriverModel));
          } else {
            emit(NearbyDriverError(
                message: nearbyDriverModel.message.toString()));
          }
        }
      }
    });
  }
}
