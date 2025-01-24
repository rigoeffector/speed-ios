// ignore_for_file: must_be_immutable

part of 'create_client_favorite_location_bloc.dart';

abstract class CreateClientFavoriteLocationState extends Equatable {
  const CreateClientFavoriteLocationState();

  @override
  List<Object> get props => [];
}

class CreateClientFavoriteLocationInitial
    extends CreateClientFavoriteLocationState {}

class CreateClientFavoriteLocationLoading
    extends CreateClientFavoriteLocationState {}

class CreateClientFavoriteLocationSuccess
    extends CreateClientFavoriteLocationState {
  CreateClientLocationModel model;
  CreateClientFavoriteLocationSuccess({
    required this.model,
  });
}

class CreateClientFavoriteLocationError
    extends CreateClientFavoriteLocationState {
  String message;
  CreateClientFavoriteLocationError({
    required this.message,
  });
}
