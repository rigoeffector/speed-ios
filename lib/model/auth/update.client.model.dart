class UpdateClientInfoModel {
  final String? message;
  final bool success;
  final ClientData? data; // single object (null if absent)

  const UpdateClientInfoModel({
    this.message,
    required this.success,
    this.data,
  });

  factory UpdateClientInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateClientInfoModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: _parseData(json['data']),
    );
  }

  // Accepts null / Map / List and returns the single ClientData or null.
  static ClientData? _parseData(dynamic dataJson) {
    if (dataJson == null) return null;

    if (dataJson is Map<String, dynamic>) {
      return ClientData.fromJson(dataJson);
    }

    if (dataJson is List) {
      // If list, take first valid map item as the single object
      for (final item in dataJson) {
        if (item is Map<String, dynamic>) {
          return ClientData.fromJson(item);
        }
      }
      return null;
    }

    // Unexpected types (string "null", number...) -> null
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = <String, dynamic>{};
    m['message'] = message;
    m['success'] = success;
    // Serialize as object like your API sample
    m['data'] = data?.toJson() ?? {};
    return m;
  }

  /// Convenience: return a list view for callers that expect a list
  List<ClientData> get dataAsList => data == null ? <ClientData>[] : <ClientData>[data!];

  @override
  String toString() =>
      'UpdateClientInfoModel(success: $success, hasData: ${data != null}, message: $message)';
}

class ClientData {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;
  final String? deviceToken;
  final String? verificationCode;
  final String? verificationCodeExpiry;

  const ClientData({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
    this.deviceToken,
    this.verificationCode,
    this.verificationCodeExpiry,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: _parseInt(json['id']),
      fname: _fromJsonString(json['fname'])?.trim(),
      lname: _fromJsonString(json['lname'])?.trim(),
      phone: _fromJsonString(json['phone'])?.trim(),
      status: _fromJsonString(json['status'])?.trim(),
      deviceToken: _fromJsonString(json['deviceToken']),
      verificationCode: _fromJsonString(json['verificationCode'])?.trim(),
      verificationCodeExpiry: _fromJsonString(json['verificationCodeExpiry']),
    );
  }

  static String? _fromJsonString(dynamic v) {
    if (v == null) return null;
    if (v is! String) return v.toString().trim();
    final t = v.trim();
    return (t.toLowerCase() == 'null') ? null : t;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    try {
      return int.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  DateTime? get expiryDateTime =>
      verificationCodeExpiry == null ? null : DateTime.tryParse(verificationCodeExpiry!);

  bool get isExpiryValid => expiryDateTime != null && expiryDateTime!.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fname': fname ?? 'null',
      'lname': lname ?? 'null',
      'phone': phone,
      'status': status ?? 'null',
      'deviceToken': deviceToken ?? 'null',
      'verificationCode': verificationCode,
      'verificationCodeExpiry': verificationCodeExpiry,
    };
  }

  @override
  String toString() =>
      'ClientData(id:$id, fname:$fname, lname:$lname, phone:$phone, status:$status)';
}
