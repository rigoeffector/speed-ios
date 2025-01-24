class PickUpLocationModel {
  String? id;
  String? clientId;
  String? title;
  String? address;
  String? latitude;
  String? longitude;
  String? status;

  PickUpLocationModel(
      {this.id,
        this.clientId,
        this.title,
        this.address,
        this.latitude,
        this.longitude,
        this.status});

  PickUpLocationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    clientId = json['client_id'];
    title = json['title'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['client_id'] = this.clientId;
    data['title'] = this.title;
    data['address'] = this.address;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['status'] = this.status;
    return data;
  }
}
