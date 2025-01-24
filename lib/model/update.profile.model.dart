class UpdateProfileModel {
  int? statusCode;
  bool success = false;
  String? message;
  UpdateProfile? updateData;

  UpdateProfileModel(
      {this.statusCode, required this.success, this.message, this.updateData});

  UpdateProfileModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'] ?? false;
    message = json['message'];
    updateData = json['update_data'] != null
        ? UpdateProfile.fromJson(json['update_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['success'] = success;
    data['message'] = message;
    if (updateData != null) {
      data['update_data'] = updateData!.toJson();
    }
    return data;
  }
}

class UpdateProfile {
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

  UpdateProfile(
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

  UpdateProfile.fromJson(Map<String, dynamic> json) {
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
