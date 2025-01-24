class ClientFavoriteLocationModel {
  int? statusCode;
  bool status = false;
  String? message;
  List<AddressRecords>? addressRecords;

  ClientFavoriteLocationModel(
      {this.statusCode,
      required this.status,
      this.message,
      this.addressRecords});

  ClientFavoriteLocationModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    status = json['status'] ?? false;
    message = json['message'];
    if (json['address_records'] != null) {
      addressRecords = <AddressRecords>[];
      json['address_records'].forEach((v) {
        addressRecords!.add(AddressRecords.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['status'] = status;
    data['message'] = message;
    if (addressRecords != null) {
      data['address_records'] = addressRecords!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AddressRecords {
  String? id;
  String? clientId;
  String? title;
  String? address;
  String? phone;
  String? latitude;
  String? longitude;
  String? status;

  AddressRecords(
      {this.id,
      this.clientId,
      this.title,
      this.address,
      this.phone,
      this.latitude,
      this.longitude,
      this.status});

  AddressRecords.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    title = json['title'];
    address = json['address'];
    phone = json['phone'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['client_id'] = clientId;
    data['title'] = title;
    data['address'] = address;
    data['phone'] = phone;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['status'] = status;
    return data;
  }
}
