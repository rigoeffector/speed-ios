import 'package:flutter/material.dart';

enum HomeState {
  normal,
  selectCity,
  pickDriver,
  chooseCar,
  setDestination,
  incomingRequest,
  driverFound,
  searchNearBy,
  myInfo,
  otp,alreadyAccount, bookTrip,setPickTripType
}

class HomeController extends ChangeNotifier {
  HomeState homeState = HomeState.normal;
  void changeHomeState(HomeState state) {
    homeState = state;
    notifyListeners();
  }
}
