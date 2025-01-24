class CreateClientLocationModel {
  int? statusCade;
  bool status = false;
  String? message;
  LocationData? locationData;

  CreateClientLocationModel(
      {this.statusCade, required this.status, this.message, this.locationData});

  CreateClientLocationModel.fromJson(Map<String, dynamic> json) {
    statusCade = json['statusCade'];
    status = json['status'] ?? false;
    message = json['message'];
    locationData = json['location_data'] != null
        ? LocationData.fromJson(json['location_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCade'] = statusCade;
    data['status'] = status;
    data['message'] = message;
    if (locationData != null) {
      data['location_data'] = locationData!.toJson();
    }
    return data;
  }
}

class LocationData {
  String? id;
  String? clientId;
  String? title;
  String? address;
  String? phone;
  String? latitude;
  String? longitude;
  String? status;

  LocationData(
      {this.id,
      this.clientId,
      this.title,
      this.address,
      this.phone,
      this.latitude,
      this.longitude,
      this.status});

  LocationData.fromJson(Map<String, dynamic> json) {
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
