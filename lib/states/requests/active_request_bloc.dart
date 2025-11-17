import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../api/auth.service.dart';
import '../../model/active_request_model.dart';

part 'active_request_event.dart';
part 'active_request_state.dart';

class ActiveRequestBloc extends Bloc<ActiveRequestEvent, ActiveRequestState> {
  final AuthService _service;

  ActiveRequestBloc(this._service) : super(ActiveRequestInitial()) {
    on<FetchActiveRequestEvent>(_onFetchActiveRequest);
    on<ClearActiveRequestEvent>(_onClearActiveRequest);
  }

  Future<void> _onFetchActiveRequest(
    FetchActiveRequestEvent event,
    Emitter<ActiveRequestState> emit,
  ) async {
    emit(ActiveRequestLoading());

    try {
      final result = await _service.getActiveRequest(event.clientId);

      if (result.data != null) {
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('activeRequest', jsonEncode(result.data!.toJson()));

        emit(ActiveRequestSuccess(
          activeRequestModel: result,
          hasActiveRequest: true,
        ));
      } else {
        // Remove cache if no active request exists
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('activeRequest');

        emit(NoActiveRequest());
      }
    } catch (e) {
      // On API failure → try loading from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('activeRequest');

      if (cachedData != null) {
        final data = ActiveRequestData.fromJson(jsonDecode(cachedData));
        debugPrint(data.toString());

        emit(
          ActiveRequestSuccess(
            activeRequestModel: ActiveRequestModel(
              success: true,
              message: 'Loaded from cache',
              data: data,
            ),
            hasActiveRequest: true,
          ),
        );
      } else {
        emit(ActiveRequestError(message: e.toString()));
      }
    }
  }

  Future<void> _onClearActiveRequest(
    ClearActiveRequestEvent event,
    Emitter<ActiveRequestState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeRequest');

      emit(NoActiveRequest());
    } catch (e) {
      emit(ActiveRequestError(message: 'Failed to clear active request'));
    }
  }
}
