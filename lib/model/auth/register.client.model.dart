import 'package:speed_ios/model/user_model.dart';

class RegisterClientModel {
  String? message;
  bool success = false;
  List<ClientData>? data;

  RegisterClientModel({this.message, required this.success, this.data});

  RegisterClientModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'] ?? false;
    if (json['data'] != null) {
      data = <ClientData>[];
      json['data'].forEach((v) {
        data!.add(ClientData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ClientData {
  int? id;
  String? fname;
  String? lname;
  String? phone;
  String? status;

  ClientData({this.id, this.fname, this.lname, this.phone, this.status});

  ClientData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fname = json['fname'];
    lname = json['lname'];
    phone = json['phone'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fname'] = fname;
    data['lname'] = lname;
    data['phone'] = phone;
    data['status'] = status;
    return data;
  }
}
