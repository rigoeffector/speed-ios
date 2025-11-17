// ignore_for_file: prefer_const_constructors_in_immutables

part of 'active_request_bloc.dart';

abstract class ActiveRequestEvent extends Equatable {
  const ActiveRequestEvent();

  @override
  List<Object?> get props => [];
}

class FetchActiveRequestEvent extends ActiveRequestEvent {
  final int clientId;

  FetchActiveRequestEvent({required this.clientId});

  @override
  List<Object?> get props => [clientId];
}

class ClearActiveRequestEvent extends ActiveRequestEvent {}
