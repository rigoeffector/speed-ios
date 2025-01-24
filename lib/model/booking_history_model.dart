class BookingModel {
  String? id;
  String? clientId;
  String? tripRefferenceNo;
  String? tripType;
  String? tripPrice;
  String? tripDate;
  String? tripTime;
  String? sourceLocation;
  String? destinationLocation;
  String? sourceLat;
  String? sourceLng;
  String? destinationLat;
  String? destinationLng;
  String? approvedBy;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? driver;
  String? driverPhone;
  String? category;

  BookingModel(
      {this.id,
        this.clientId,
        this.tripRefferenceNo,
        this.tripType,
        this.tripPrice,
        this.tripDate,
        this.tripTime,
        this.sourceLocation,
        this.destinationLocation,
        this.sourceLat,
        this.sourceLng,
        this.destinationLat,
        this.destinationLng,
        this.approvedBy,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.driver,
        this.driverPhone,
        this.category});

  BookingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    tripRefferenceNo = json['trip_refference_no'];
    tripType = json['trip_type'];
    tripPrice = json['trip_price'];
    tripDate = json['trip_date'];
    tripTime = json['trip_time'];
    sourceLocation = json['source_location'];
    destinationLocation = json['destination_location'];
    sourceLat = json['source_lat'];
    sourceLng = json['source_lng'];
    destinationLat = json['destination_lat'];
    destinationLng = json['destination_lng'];
    approvedBy = json['approved_by'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    driver = json['driver'];
    driverPhone = json['driver_phone'];
    category = json['category'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['client_id'] = this.clientId;
    data['trip_refference_no'] = this.tripRefferenceNo;
    data['trip_type'] = this.tripType;
    data['trip_price'] = this.tripPrice;
    data['trip_date'] = this.tripDate;
    data['trip_time'] = this.tripTime;
    data['source_location'] = this.sourceLocation;
    data['destination_location'] = this.destinationLocation;
    data['source_lat'] = this.sourceLat;
    data['source_lng'] = this.sourceLng;
    data['destination_lat'] = this.destinationLat;
    data['destination_lng'] = this.destinationLng;
    data['approved_by'] = this.approvedBy;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['driver'] = this.driver;
    data['driver_phone'] = this.driverPhone;
    data['category'] = this.category;
    return data;
  }
}
