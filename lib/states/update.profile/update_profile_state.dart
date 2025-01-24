// ignore_for_file: must_be_immutable

part of 'update_profile_bloc.dart';

abstract class UpdateProfileState extends Equatable {
  const UpdateProfileState();

  @override
  List<Object> get props => [];
}

class UpdateProfileInitial extends UpdateProfileState {}

class UpdateClientLoading extends UpdateProfileState {}

class UpdateProfileSuccess extends UpdateProfileState {
  UpdateProfileModel updateProfileModel;
  UpdateProfileSuccess({
    required this.updateProfileModel,
  });
}

class UpdateProfileError extends UpdateProfileState {
  String message;
  UpdateProfileError({
    required this.message,
  });
}
