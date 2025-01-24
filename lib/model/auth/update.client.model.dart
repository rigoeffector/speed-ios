class UpdateClientInfoModel {
  String? message;
  bool success = false;
  List<Data>? data;

  UpdateClientInfoModel({this.message, required this.success, this.data});

  UpdateClientInfoModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'] ?? false;
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  int? id;
  String? fname;
  String? lname;
  String? phone;
  String? status;

  Data({this.id, this.fname, this.lname, this.phone, this.status});

  Data.fromJson(Map<String, dynamic> json) {
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
