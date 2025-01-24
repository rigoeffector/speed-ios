// ignore_for_file: must_be_immutable

part of 'create_client_favorite_location_bloc.dart';

abstract class CreateClientFavoriteLocationEvent extends Equatable {
  const CreateClientFavoriteLocationEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends CreateClientFavoriteLocationEvent {}

class HandleCreateLocationEvent extends CreateClientFavoriteLocationEvent {
  String latitude;
  String longitude;
  String clientId;
  String title;
  String address;
  String phone;

  HandleCreateLocationEvent({
    required this.latitude,
    required this.longitude,
    required this.clientId,
    required this.title,
    required this.address,
    required this.phone,
  });
}
