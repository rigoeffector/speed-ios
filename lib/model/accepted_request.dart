class AcceptedRequestModel {
  String? id;
  String? driverName;
  String? driverPhone;
  String? category;
  String? carName;
  String? carSeats;
  String? carPlateNumber;

  AcceptedRequestModel(
      {this.id,
        this.driverName,
        this.driverPhone,
        this.category,
        this.carName,
        this.carSeats,
        this.carPlateNumber});

  AcceptedRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverName = json['driver_name'];
    driverPhone = json['driver_phone'];
    category = json['category'];
    carName = json['car_name'];
    carSeats = json['car_seats'];
    carPlateNumber = json['car_plate_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['driver_name'] = this.driverName;
    data['driver_phone'] = this.driverPhone;
    data['category'] = this.category;
    data['car_name'] = this.carName;
    data['car_seats'] = this.carSeats;
    data['car_plate_number'] = this.carPlateNumber;
    return data;
  }
}
