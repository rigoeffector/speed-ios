// ignore_for_file: must_be_immutable

part of 'client_profile_bloc.dart';

abstract class ClientProfileState extends Equatable {
  const ClientProfileState();
  
  @override
  List<Object> get props => [];
}

class ClientProfileInitial extends ClientProfileState {}

class ClientProfileLoading extends ClientProfileState {}

class ClientProfileSuccess extends ClientProfileState {
  ClientProfileModel clientProfileModel;
  ClientProfileSuccess({
    required this.clientProfileModel,
  });
}

class ClientProfileError extends ClientProfileState {
  String message;
  ClientProfileError({
    required this.message,
  });
}