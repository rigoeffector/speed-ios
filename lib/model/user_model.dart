class UserModel {
  int? status;
  String? message;
  List<ClientData>? clientData;

  UserModel({this.status, this.message, this.clientData});

  UserModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['client_data'] != null) {
      clientData = <ClientData>[];
      json['client_data'].forEach((v) {
        clientData!.add(ClientData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (clientData != null) {
      data['client_data'] = clientData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ClientData {
  String? id;
  String? names;
  String? phone;
  String? email;
  String? gender;
  String? password;
  String? photo;
  String? category;
  String? addressLocation;

  ClientData(
      {this.id,
      this.names,
      this.phone,
      this.email,
      this.gender,
      this.password,
      this.photo,
      this.category,
      this.addressLocation});

  ClientData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    names = json['names'];
    phone = json['phone'];
    email = json['email'];
    gender = json['gender'];
    password = json['password'];
    photo = json['photo'];
    category = json['category'];
    addressLocation = json['address_location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['names'] = names;
    data['phone'] = phone;
    data['email'] = email;
    data['gender'] = gender;
    data['password'] = password;
    data['photo'] = photo;
    data['category'] = category;
    data['address_location'] = addressLocation;
    return data;
  }
}
