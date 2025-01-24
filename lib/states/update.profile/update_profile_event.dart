// ignore_for_file: must_be_immutable

part of 'update_profile_bloc.dart';

abstract class UpdateProfileEvent extends Equatable {
  const UpdateProfileEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends UpdateProfileEvent {}

class HandleUpdateProfileInformation extends UpdateProfileEvent {
  String clientId;
  String clientName;
  PickedFile photo;

  HandleUpdateProfileInformation({
    required this.clientId,
    required this.clientName,
    required this.photo
  });
}
