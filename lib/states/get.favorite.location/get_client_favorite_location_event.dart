// ignore_for_file: must_be_immutable

part of 'get_client_favorite_location_bloc.dart';

abstract class GetClientFavoriteLocationEvent extends Equatable {
  const GetClientFavoriteLocationEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends GetClientFavoriteLocationEvent {}

class FetchFavoriteLocationEvent extends GetClientFavoriteLocationEvent {
  String clientId;

  FetchFavoriteLocationEvent({required this.clientId});
}
