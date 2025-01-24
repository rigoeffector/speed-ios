// ignore_for_file: must_be_immutable

part of 'get_client_favorite_location_bloc.dart';

abstract class GetClientFavoriteLocationState extends Equatable {
  const GetClientFavoriteLocationState();

  @override
  List<Object> get props => [];
}

class GetClientFavoriteLocationInitial extends GetClientFavoriteLocationState {}

class GetClientFavoriteLocationLoading extends GetClientFavoriteLocationState {}

class GetClientFavoriteLocationSuccess extends GetClientFavoriteLocationState {
  ClientFavoriteLocationModel model;
  GetClientFavoriteLocationSuccess({
    required this.model,
  });
}

class GetClientFavoriteLocationError extends GetClientFavoriteLocationState {
  String message;
  GetClientFavoriteLocationError({
    required this.message,
  });
}
