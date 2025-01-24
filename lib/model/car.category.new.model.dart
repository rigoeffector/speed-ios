class CarCategoryNewModel {
  int? statusCode;
  bool status = false;
  String? message;
  List<CarCategory>? carCategory;

  CarCategoryNewModel({this.statusCode, required this.status,this.message, this.carCategory});

  CarCategoryNewModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    status = json['status'];
    message = json['message'];
    if (json['car_category'] != null) {
      carCategory = <CarCategory>[];
      json['car_category'].forEach((v) {
        carCategory!.add(CarCategory.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['status'] = status;
    data['message'] = message;
    if (carCategory != null) {
      data['car_category'] = carCategory!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CarCategory {
  String? id;
  String? title;
  String? photo;
  String? pricePerMeter;
  String? available;

  CarCategory(
      {this.id, this.title, this.photo, this.pricePerMeter, this.available});

  CarCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    photo = json['photo'];
    pricePerMeter = json['price_per_meter'];
    available = json['available'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['photo'] = photo;
    data['price_per_meter'] = pricePerMeter;
    data['available'] = available;
    return data;
  }
}
