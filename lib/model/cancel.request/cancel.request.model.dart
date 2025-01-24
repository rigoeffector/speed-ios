class CancelRequestModel {
  int? statusCade;
  bool status = false;
  String? message;

  CancelRequestModel({this.statusCade, required this.status, this.message});

  CancelRequestModel.fromJson(Map<String, dynamic> json) {
    statusCade = json['statusCade'];
    status = json['status'] ?? false;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCade'] = statusCade;
    data['status'] = status;
    data['message'] = message;
    return data;
  }
}
