// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
part of 'update_client_bloc.dart';

class UpdateClientEvent extends Equatable {
  const UpdateClientEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends UpdateClientEvent {}

class HandleUpdateClientInformation extends UpdateClientEvent {
  String clientId;
  String fname;
  String lname;

  HandleUpdateClientInformation({
    required this.clientId,
    required this.fname,
    required this.lname,
  });
}
