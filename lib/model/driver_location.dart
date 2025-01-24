class DriverLocationModel {
  String? id;
  String? driverId;
  String? car;
  String? city;
  String? driverCategory;
  String? driverName;
  String? driverPhone;
  String? isOnline;
  double? latitude;
  double? longitude;
  String? model;
  String? price;
  String? createdAt;
  String? updatedAt;

  DriverLocationModel(
      {this.id,
        this.driverId,
        this.car,
        this.city,
        this.driverCategory,
        this.driverName,
        this.driverPhone,
        this.isOnline,
        this.latitude,
        this.longitude,
        this.model,
        this.price,
        this.createdAt,
        this.updatedAt});

  DriverLocationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverId = json['driver_id'];
    car = json['car'];
    city = json['city'];
    driverCategory = json['driver_category'];
    driverName = json['driver_name'];
    driverPhone = json['driver_phone'];
    isOnline = json['is_online'];
    latitude = double.tryParse(json['latitude']);
    longitude = double.tryParse(json['longitude']);
    model = json['model'];
    price = json['price'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['driver_id'] = driverId;
    data['car'] = car;
    data['city'] = city;
    data['driver_category'] = driverCategory;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
    data['is_online'] = isOnline;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['model'] = model;
    data['price'] = price;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
