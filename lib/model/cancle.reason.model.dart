class CancelReasonModel {
  String? id;
  String? reason;

  CancelReasonModel({this.id, this.reason});

  CancelReasonModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reason = json['reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['reason'] = reason;
    return data;
  }
}
