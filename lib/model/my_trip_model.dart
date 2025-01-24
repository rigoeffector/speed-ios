class MyTripModel {
  String? id;
  String? clientId;
  String? tripType;
  String? vehiType;
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

  MyTripModel(
      {this.id,
        this.clientId,
        this.tripType,
        this.vehiType,
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

  MyTripModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    tripType = json['trip_type'];
    vehiType = json['vehi_type'];
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['client_id'] = this.clientId;
    data['trip_type'] = this.tripType;
    data['vehi_type'] = this.vehiType;
    data['trip_price'] = this.tripPrice;
    data['source'] = this.source;
    data['destination'] = this.destination;
    data['s_latitude'] = this.sLatitude;
    data['s_longitude'] = this.sLongitude;
    data['d_latitude'] = this.dLatitude;
    data['d_longitude'] = this.dLongitude;
    data['status'] = this.status;
    data['accepted_by'] = this.acceptedBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
