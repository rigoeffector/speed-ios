class UserSentRequestsModel {
  final String? message;
  final bool success;
  final RequestData? data;

  const UserSentRequestsModel({
    required this.message,
    required this.success,
    required this.data,
  });

  factory UserSentRequestsModel.fromJson(Map<String, dynamic> json) {
    return UserSentRequestsModel(
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? RequestData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['message'] = message;
    dataMap['success'] = success;
    if (data != null) {
      dataMap['data'] = data!.toJson();
    }
    return dataMap;
  }

  @override
  String toString() => 'UserSentRequestsModel(success: $success, totalItems: ${data?.totalItems}, message: $message)';
}

class RequestData {
  final List<RequestContent> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  const RequestData({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      content: _parseContent(json['content']),
      currentPage: json['currentPage'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  static List<RequestContent> _parseContent(dynamic contentJson) {
    if (contentJson == null) {
      print('Info: content is null, defaulting to empty list');
      return <RequestContent>[];
    }

    if (contentJson is List) {
      return contentJson
          .where((item) => item is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => RequestContent.fromJson(item))
          .toList();
    } else if (contentJson is Map<String, dynamic>) {
      print('Info: Converted single Map to List for content');
      return <RequestContent>[RequestContent.fromJson(contentJson)];
    } else {
      print('Warning: Unexpected type for content: ${contentJson.runtimeType}. Defaulting to empty list.');
      return <RequestContent>[];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    if (content.isNotEmpty) {
      dataMap['content'] = content.map((v) => v.toJson()).toList();
    }
    dataMap['currentPage'] = currentPage;
    dataMap['totalItems'] = totalItems;
    dataMap['totalPages'] = totalPages;
    return dataMap;
  }

  @override
  String toString() => 'RequestData(currentPage: $currentPage, totalItems: $totalItems, totalPages: $totalPages, contentLength: ${content.length})';
}

class RequestContent {
  final int? id;
  final MotorBiker? motorBiker;
  final Client? client;
  final String? requestType;
  final String? requestedTime;
  final String? createdAt;
  final String? updatedAt;
  final String? originLocation;
  final String? destinationLocation;
  final String? status;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final int? priorityLevel;
  final bool? manualDispatch;

  const RequestContent({
    this.id,
    this.motorBiker,
    this.client,
    this.requestType,
    this.requestedTime,
    this.createdAt,
    this.updatedAt,
    this.originLocation,
    this.destinationLocation,
    this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.priorityLevel,
    this.manualDispatch,
  });

  factory RequestContent.fromJson(Map<String, dynamic> json) {
    return RequestContent(
      id: json['id'] as int?,
      motorBiker: json['motorBiker'] != null
          ? MotorBiker.fromJson(json['motorBiker'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? Client.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      requestType: _fromJsonString(json['requestType']),
      requestedTime: _fromJsonString(json['requestedTime']),
      createdAt: _fromJsonString(json['createdAt']),
      updatedAt: _fromJsonString(json['updatedAt']),
      originLocation: _fromJsonString(json['originLocation']),
      destinationLocation: _fromJsonString(json['destinationLocation']),
      status: _fromJsonString(json['status']),
      driverId: json['driverId'] as int?,
      driverName: _fromJsonString(json['driverName']),
      driverPhone: _fromJsonString(json['driverPhone']),
      priorityLevel: json['priorityLevel'] as int?,
      manualDispatch: json['manualDispatch'] as bool?,
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  // Optional: DateTime parsers
  DateTime? get requestedDateTime => requestedTime != null
      ? DateTime.tryParse(requestedTime!)
      : null;

  DateTime? get createdDateTime => createdAt != null
      ? DateTime.tryParse(createdAt!)
      : null;

  DateTime? get updatedDateTime => updatedAt != null
      ? DateTime.tryParse(updatedAt!)
      : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    if (motorBiker != null) {
      dataMap['motorBiker'] = motorBiker!.toJson();
    }
    if (client != null) {
      dataMap['client'] = client!.toJson();
    }
    dataMap['requestType'] = requestType;
    dataMap['requestedTime'] = requestedTime;
    dataMap['createdAt'] = createdAt;
    dataMap['updatedAt'] = updatedAt;
    dataMap['originLocation'] = originLocation;
    dataMap['destinationLocation'] = destinationLocation;
    dataMap['status'] = status;
    dataMap['driverId'] = driverId;
    dataMap['driverName'] = driverName;
    dataMap['driverPhone'] = driverPhone;
    dataMap['priorityLevel'] = priorityLevel;
    dataMap['manualDispatch'] = manualDispatch;
    return dataMap;
  }

  @override
  String toString() => 'RequestContent(id: $id, status: $status, requestType: $requestType, driverName: $driverName)';
}

class MotorBiker {
  final int? id;
  final String? motorType;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? plateNumber;
  final String? chassisNumber;
  final String? vestNumber;
  final String? status;
  final String? deviceToken;
  final bool? speedDriverAccess;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? fullName;

  const MotorBiker({
    this.id,
    this.motorType,
    this.firstName,
    this.lastName,
    this.phone,
    this.plateNumber,
    this.chassisNumber,
    this.vestNumber,
    this.status,
    this.deviceToken,
    this.speedDriverAccess,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.fullName,
  });

  factory MotorBiker.fromJson(Map<String, dynamic> json) {
    return MotorBiker(
      id: json['id'] as int?,
      motorType: _fromJsonString(json['motorType']),
      firstName: _fromJsonString(json['firstName']),
      lastName: _fromJsonString(json['lastName']),
      phone: _fromJsonString(json['phone']),
      plateNumber: _fromJsonString(json['plateNumber']),
      chassisNumber: _fromJsonString(json['chassisNumber']),
      vestNumber: _fromJsonString(json['vestNumber']),
      status: _fromJsonString(json['status']),
      deviceToken: _fromJsonString(json['deviceToken']),
      speedDriverAccess: json['speedDriverAccess'] as bool?,
      isActive: json['isActive'] as bool?,
      createdAt: _fromJsonString(json['createdAt']),
      updatedAt: _fromJsonString(json['updatedAt']),
      fullName: _fromJsonString(json['fullName']),
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  DateTime? get createdDateTime => createdAt != null
      ? DateTime.tryParse(createdAt!)
      : null;

  DateTime? get updatedDateTime => updatedAt != null
      ? DateTime.tryParse(updatedAt!)
      : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    dataMap['motorType'] = motorType;
    dataMap['firstName'] = firstName;
    dataMap['lastName'] = lastName;
    dataMap['phone'] = phone;
    dataMap['plateNumber'] = plateNumber;
    dataMap['chassisNumber'] = chassisNumber;
    dataMap['vestNumber'] = vestNumber;
    dataMap['status'] = status;
    dataMap['deviceToken'] = deviceToken;
    dataMap['speedDriverAccess'] = speedDriverAccess;
    dataMap['isActive'] = isActive;
    dataMap['createdAt'] = createdAt;
    dataMap['updatedAt'] = updatedAt;
    dataMap['fullName'] = fullName;
    return dataMap;
  }

  @override
  String toString() => 'MotorBiker(id: $id, fullName: $fullName, phone: $phone, status: $status)';
}

class Client {
  final int? id;
  final String? fname;
  final String? lname;
  final String? phone;
  final String? status;

  const Client({
    this.id,
    this.fname,
    this.lname,
    this.phone,
    this.status,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      fname: _fromJsonString(json['fname']),
      lname: _fromJsonString(json['lname']),
      phone: _fromJsonString(json['phone']),
      status: _fromJsonString(json['status']),
    );
  }

  static String? _fromJsonString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    return (value.toLowerCase() == 'null') ? null : value;
  }

  String? get fullName {
    if (fname == null && lname == null) return null;
    return '${fname ?? ''} ${lname ?? ''}'.trim();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['id'] = id;
    dataMap['fname'] = fname;
    dataMap['lname'] = lname;
    dataMap['phone'] = phone;
    dataMap['status'] = status;
    return dataMap;
  }

  @override
  String toString() => 'Client(id: $id, fullName: $fullName, phone: $phone, status: $status)';
}