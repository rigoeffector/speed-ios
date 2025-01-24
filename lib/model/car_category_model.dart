class CarCategoryModel {
  String? id;
  String? title;
  String? photo;
  String? pricePerMeter;
  String? available;

  CarCategoryModel(
      {this.id,
        this.title,
        this.photo,
        this.pricePerMeter,
        this.available,
       });

  CarCategoryModel.fromJson(Map<String, dynamic> json) {
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
