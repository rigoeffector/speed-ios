// ignore_for_file: must_be_immutable

part of 'client_profile_bloc.dart';

abstract class ClientProfileEvent extends Equatable {
  const ClientProfileEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends ClientProfileEvent {}

class FetchAllClientInformation extends ClientProfileEvent {
  String clientId;

  FetchAllClientInformation({
    required this.clientId,
  });
}