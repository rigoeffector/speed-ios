import 'package:flutter/material.dart';
enum DriverHomeState {normal, incomingRequest, driverArrived, startRide, paymentMethod}

class HomeDriverController extends ChangeNotifier{
  DriverHomeState driverHomeState = DriverHomeState.normal;
  void changeDriverHomeState(DriverHomeState state){
    driverHomeState = state;
    notifyListeners();
  }
}