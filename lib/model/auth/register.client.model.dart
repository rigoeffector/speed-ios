class RegisterClientModel {
  final String? message;
  final bool success;
  final List<ClientData> data; // Non-nullable: always [] if empty/null

  const RegisterClientModel({
    required this.message,
    required this.success,
    required this.data,
  });
  factory RegisterClientModel.fromJson(Map<String, dynamic> json) {
    return RegisterClientModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: _parseData(json['data']),
    );
  }

  static List<ClientData> _parseData(dynamic dataJson) {
    if (dataJson == null) {
      print('Info: data is null, defaulting to empty list');
      return <ClientData>[];
    }

    if (dataJson is List) {
      // Standard: List of maps
      return dataJson
          .where((item) => item is Map<String, dynamic>) // Filter invalid
          .cast<Map<String, dynamic>>()
          .map((item) => ClientData.fromJson(item))
          .toList();
    } else if (dataJson is Map<String, dynamic>) {
      // Fallback: Single object → list of 1
      print('Info: Converted single Map to List for data');
      return <ClientData>[ClientData.fromJson(dataJson)];
    } else {
      // Unexpected (e.g., String "null", int)
      print('Warning: Unexpected type for data: ${dataJson.runtimeType}. Defaulting to empty list.');
      return <ClientData>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['message'] = message;
    dataMap['success'] = success;
    if (data.isNotEmpty) { // Safe: no !
      dataMap['data'] = data.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }

  @override
  String toString() => 'RegisterClientModel(success: $success, dataLength: ${data.length}, message: $message)';
}

class ClientData {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;
  final String? verificationCode;
  final String? deviceToken; // "null" string → null
  final String? verificationCodeExpiry; // e.g., ISO string

  const ClientData({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
    this.verificationCode,
    this.deviceToken,
    this.verificationCodeExpiry,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: json['id'] as int?,
      fname: _fromJsonString(json['fname']),
      lname: _fromJsonString(json['lname']),
      phone: _fromJsonString(json['phone']),
      status: _fromJsonString(json['status']),
      verificationCode: _fromJsonString(json['verificationCode']),
      deviceToken: _fromJsonString(json['deviceToken']), // Key fix: "null" → null
      verificationCodeExpiry: _fromJsonString(json['verificationCodeExpiry']),
    );
  }

  // Helper: Accepts null or String; converts "null" string to actual null
  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString(); // Fallback for non-string
    return (value.toLowerCase() == 'null') ? null : value;
  }

  // Optional: Safe DateTime parser for expiry
  DateTime? get expiryDateTime => verificationCodeExpiry != null
      ? DateTime.tryParse(verificationCodeExpiry!)
      : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    dataMap['fname'] = fname;
    dataMap['lname'] = lname;
    dataMap['phone'] = phone;
    dataMap['status'] = status;
    dataMap['verificationCode'] = verificationCode;
    dataMap['deviceToken'] = deviceToken ?? 'null'; // Serialize null as "null" if needed by API
    dataMap['verificationCodeExpiry'] = verificationCodeExpiry;
    return dataMap;
  }

  @override
  String toString() => 'ClientData(id: $id, phone: $phone, deviceToken: $deviceToken, expiry: $verificationCodeExpiry)';
}