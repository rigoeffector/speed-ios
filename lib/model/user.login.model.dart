class UserLoginModel {
  int? statusCode;
  bool status = false;
  String? message;
  UserLoginData? userLoginData;

  UserLoginModel(
      {this.statusCode,required this.status, this.message, this.userLoginData});

  UserLoginModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    status = json['status'] ?? false;
    message = json['message'];
    userLoginData = json['user_login_data'] != null
        ? UserLoginData.fromJson(json['user_login_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['status'] = status;
    data['message'] = message;
    if (userLoginData != null) {
      data['user_login_data'] = userLoginData!.toJson();
    }
    return data;
  }
}

class UserLoginData {
  String? id;
  String? names;
  String? phone;
  String? email;
  String? gender;
  String? password;
  String? photo;
  String? category;
  String? addressLocation;
  String? status;

  UserLoginData(
      {this.id,
      this.names,
      this.phone,
      this.email,
      this.gender,
      this.password,
      this.photo,
      this.category,
      this.addressLocation,
      this.status});

  UserLoginData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    names = json['names'];
    phone = json['phone'];
    email = json['email'];
    gender = json['gender'];
    password = json['password'];
    photo = json['photo'];
    category = json['category'];
    addressLocation = json['address_location'];
    status = json['status'];
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
    data['status'] = status;
    return data;
  }
}
