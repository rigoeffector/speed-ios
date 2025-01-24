class ConfrimTripModel {
  int? statusCode;
  bool status = false;
  String? message;
  RequestData? requestData;

  ConfrimTripModel(
      {this.statusCode, required this.status, this.message, this.requestData});

  ConfrimTripModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    status = json['status'] ?? false;
    message = json['message'];
    requestData = json['request_data'] != null
        ? RequestData.fromJson(json['request_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['status'] = status;
    data['message'] = message;
    if (requestData != null) {
      data['request_data'] = requestData!.toJson();
    }
    return data;
  }
}

class RequestData {
  String? id;
  String? clientId;
  String? tripType;
  String? tripPrice;
  String? source;
  String? destination;
  String? sLatitude;
  String? sLongitude;
  String? dLatitude;
  String? dLongitude;
  String? status;
  String? acceptedBy;
  String? createdAt;
  String? updatedAt;

  RequestData(
      {this.id,
      this.clientId,
      this.tripType,
      this.tripPrice,
      this.source,
      this.destination,
      this.sLatitude,
      this.sLongitude,
      this.dLatitude,
      this.dLongitude,
      this.status,
      this.acceptedBy,
      this.createdAt,
      this.updatedAt});

  RequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    tripType = json['trip_type'];
    tripPrice = json['trip_price'];
    source = json['source'];
    destination = json['destination'];
    sLatitude = json['s_latitude'];
    sLongitude = json['s_longitude'];
    dLatitude = json['d_latitude'];
    dLongitude = json['d_longitude'];
    status = json['status'];
    acceptedBy = json['accepted_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['client_id'] = clientId;
    data['trip_type'] = tripType;
    data['trip_price'] = tripPrice;
    data['source'] = source;
    data['destination'] = destination;
    data['s_latitude'] = sLatitude;
    data['s_longitude'] = sLongitude;
    data['d_latitude'] = dLatitude;
    data['d_longitude'] = dLongitude;
    data['status'] = status;
    data['accepted_by'] = acceptedBy;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
