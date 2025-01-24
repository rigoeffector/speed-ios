class MenuModel {
  String? id;
  String? name;
  String? icon;

  MenuModel(
      {this.id,
        this.name, this.icon});

  MenuModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    icon = json['icon'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['icon'] = icon;

    return data;
  }
}