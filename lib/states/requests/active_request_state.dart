// ignore_for_file: must_be_immutable

part of 'active_request_bloc.dart';

class ActiveRequestState extends Equatable {
  const ActiveRequestState();

  @override
  List<Object?> get props => [];
}

class ActiveRequestInitial extends ActiveRequestState {}

class ActiveRequestLoading extends ActiveRequestState {}

class ActiveRequestSuccess extends ActiveRequestState {
  ActiveRequestModel activeRequestModel;
  bool hasActiveRequest;

  ActiveRequestSuccess({
    required this.activeRequestModel,
    required this.hasActiveRequest,
  });

  @override
  List<Object?> get props => [activeRequestModel, hasActiveRequest];
}

class ActiveRequestError extends ActiveRequestState {
  String message;

  ActiveRequestError({required this.message});

  @override
  List<Object?> get props => [message];
}

class NoActiveRequest extends ActiveRequestState {}
