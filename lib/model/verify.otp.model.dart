class VerifyOtpModel {
  final String? message;
  final bool success;
  final VerifiedClientData? data;

  const VerifyOtpModel({
    this.message,
    required this.success,
    this.data,
  });

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: _parseData(json['data']),
    );
  }

  // Handles both single object and list gracefully
  static VerifiedClientData? _parseData(dynamic dataJson) {
    if (dataJson == null) return null;

    if (dataJson is Map<String, dynamic>) {
      return VerifiedClientData.fromJson(dataJson);
    } else if (dataJson is List && dataJson.isNotEmpty) {
      // In case API returns list unexpectedly
      final firstItem = dataJson.first;
      if (firstItem is Map<String, dynamic>) {
        return VerifiedClientData.fromJson(firstItem);
      }
    }

    // Unexpected type (e.g. string/int/null)
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'data': data?.toJson() ?? {},
    };
  }

  @override
  String toString() =>
      'VerifyOtpModel(success: $success, message: $message, data: $data)';
}

class VerifiedClientData {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;
  final String? verificationCode;

  const VerifiedClientData({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
    this.verificationCode,
  });

  factory VerifiedClientData.fromJson(Map<String, dynamic> json) {
    return VerifiedClientData(
      id: _parseInt(json['id']),
      fname: _fromJsonString(json['fname']),
      lname: _fromJsonString(json['lname']),
      phone: _fromJsonString(json['phone']),
      status: _fromJsonString(json['status']),
      verificationCode: _fromJsonString(json['verificationCode']),
    );
  }

  // Handle string "null", trim spaces, and fallback types
  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return (str.toLowerCase() == 'null' || str.isEmpty) ? null : str;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    try {
      return int.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'lname': lname,
      'phone': phone,
      'status': status,
      'verificationCode': verificationCode,
    };
  }

  @override
  String toString() =>
      'VerifiedClientData(id: $id, fname: $fname, lname: $lname, phone: $phone, status: $status)';
}
