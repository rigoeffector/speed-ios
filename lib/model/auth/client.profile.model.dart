class ClientProfileModel {
  String? message;
  bool success = false;
  List<ProfileData>? data;

  ClientProfileModel({this.message, required this.success, this.data});

  ClientProfileModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'] ?? false;
    if (json['data'] != null) {
      data = <ProfileData>[];
      json['data'].forEach((v) {
        data!.add(ProfileData.fromJson(v));
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

class ProfileData {
  int? id;
  String? fname;
  String? lname;
  String? phone;
  String? status;

  ProfileData({this.id, this.fname, this.lname, this.phone, this.status});

  ProfileData.fromJson(Map<String, dynamic> json) {
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
