import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../api/location.service.dart';
import '../../model/available.driver/available.driver.on.map.model.dart';

part 'available_driver_location_event.dart';
part 'available_driver_location_state.dart';

class AvailableDriverLocationBloc
    extends Bloc<AvailableDriverLocationEvent, AvailableDriverLocationState> {
  final LocationService locationService;
  
  double? _lastSearchLatitude;
  double? _lastSearchLongitude;
  double _currentRadius = 5.0;

  AvailableDriverLocationBloc(this.locationService)
      : super(const AvailableDriverLocationInitial()) {
    on<InitializeAvailableDriverLocationEvent>(_onInitialize);
    on<FetchAvailableDriverLocationEvent>(_onFetchAvailableDrivers);
    on<RefreshAvailableDriversEvent>(_onRefreshDrivers);
    on<ExpandSearchRadiusEvent>(_onExpandSearchRadius);
  }

  Future<void> _onInitialize(
    InitializeAvailableDriverLocationEvent event,
    Emitter<AvailableDriverLocationState> emit,
  ) async {
    emit(const AvailableDriverLocationInitial());
  }

  Future<void> _onFetchAvailableDrivers(
    FetchAvailableDriverLocationEvent event,
    Emitter<AvailableDriverLocationState> emit,
  ) async {
    emit(AvailableDriverLocationLoading(
      message: 'Finding nearby drivers...',
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: event.radiusKm,
    ));

    try {
      _lastSearchLatitude = event.latitude;
      _lastSearchLongitude = event.longitude;
      _currentRadius = event.radiusKm;

      // Use retry method for better reliability
      final response = await locationService.fetchAvailableDriverLocationWithRetry(
        event.latitude,
        event.longitude,
        event.radiusKm,
        event.limit,
      );

      if (response.success) {
        if (response.hasDrivers) {
          emit(AvailableDriverLocationSuccess(
            response: response,
            searchLatitude: event.latitude,
            searchLongitude: event.longitude,
            radiusKm: event.radiusKm,
            lastUpdated: DateTime.now(),
          ));
        } else {
          emit(AvailableDriverLocationEmpty(
            searchLatitude: event.latitude,
            searchLongitude: event.longitude,
            radiusKm: event.radiusKm,
            message: response.message.isNotEmpty
                ? response.message
                : 'No drivers available within ${event.radiusKm}km',
            canExpandSearch: event.radiusKm < 50.0,
          ));
        }
      } else {
        emit(AvailableDriverLocationError(
          message: response.message,
          lastSearchLatitude: event.latitude,
          lastSearchLongitude: event.longitude,
          radiusKm: event.radiusKm,
        ));
      }
    } catch (e) {
      emit(AvailableDriverLocationError(
        message: 'Failed to fetch drivers: ${e.toString()}',
        lastSearchLatitude: event.latitude,
        lastSearchLongitude: event.longitude,
        radiusKm: event.radiusKm,
      ));
    }
  }

  Future<void> _onRefreshDrivers(
    RefreshAvailableDriversEvent event,
    Emitter<AvailableDriverLocationState> emit,
  ) async {
    if (_lastSearchLatitude != null && _lastSearchLongitude != null) {
      add(FetchAvailableDriverLocationEvent(
        latitude: _lastSearchLatitude!,
        longitude: _lastSearchLongitude!,
        radiusKm: _currentRadius,
      ));
    }
  }

  Future<void> _onExpandSearchRadius(
    ExpandSearchRadiusEvent event,
    Emitter<AvailableDriverLocationState> emit,
  ) async {
    if (_lastSearchLatitude != null && _lastSearchLongitude != null) {
      final newRadius = (_currentRadius + 5.0).clamp(5.0, 50.0);
      
      add(FetchAvailableDriverLocationEvent(
        latitude: _lastSearchLatitude!,
        longitude: _lastSearchLongitude!,
        radiusKm: newRadius,
      ));
    }
  }
}
