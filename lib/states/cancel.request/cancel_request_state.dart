// ignore_for_file: must_be_immutable

part of 'cancel_request_bloc.dart';

abstract class CancelRequestState extends Equatable {
  const CancelRequestState();
  
  @override
  List<Object> get props => [];
}

class CancelRequestInitial extends CancelRequestState {}

class CancelRequestLoading extends CancelRequestState {}

class CancelRequestSuccess extends CancelRequestState {
  CancelRequestModel cancelRequestModel;
  CancelRequestSuccess({
    required this.cancelRequestModel,
  });
}

class CancelRequestError extends CancelRequestState {
  String message;
  CancelRequestError({
    required this.message,
  });
}
