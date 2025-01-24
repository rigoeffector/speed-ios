class ClientRequestModel {
  String? id;
  String? clientId;
  String? clientName;
  String? clientPhone;
  String? clientPackage;
  String? tripType;
  String? source;
  String? destination;
  double? sLatitude;
  double? sLongitude;
  double? dLatitude;
  double? dLongitude;
  String? status;
  String? createdAt;
  String? updatedAt;

  ClientRequestModel(
      {this.id,
        this.clientId,
        this.clientName,
        this.clientPhone,
        this.clientPackage,
        this.tripType,
        this.source,
        this.destination,
        this.sLatitude,
        this.sLongitude,
        this.dLatitude,
        this.dLongitude,
        this.status,
        this.createdAt,
        this.updatedAt});

  ClientRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    clientName = json['client_name'];
    clientPhone = json['client_phone'];
    clientPackage = json['client_package'];
    tripType = json['trip_type'];
    source = json['source'];
    destination = json['destination'];
    sLatitude = json['s_latitude'];
    sLongitude = json['s_longitude'];
    dLatitude = json['d_latitude'];
    dLongitude = json['d_longitude'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['client_id'] = clientId;
    data['client_name'] = clientName;
    data['client_phone'] = clientPhone;
    data['client_package'] = clientPackage;
    data['trip_type'] = tripType;
    data['source'] = source;
    data['destination'] = destination;
    data['s_latitude'] = sLatitude;
    data['s_longitude'] = sLongitude;
    data['d_latitude'] = dLatitude;
    data['d_longitude'] = dLongitude;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
