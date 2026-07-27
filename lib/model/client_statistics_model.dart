class ClientStatisticsModel {
  final String message;
  final bool success;
  final ClientStatisticsData? data;

  const ClientStatisticsModel({
    required this.message,
    required this.success,
    required this.data,
  });

  factory ClientStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ClientStatisticsModel(
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      data: json['data'] is Map<String, dynamic>
          ? ClientStatisticsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ClientStatisticsData {
  final int rideRequestCount;
  final int courierRequestCount;
  final List<ClientRecentRoute> recentRoutes;

  const ClientStatisticsData({
    required this.rideRequestCount,
    required this.courierRequestCount,
    required this.recentRoutes,
  });

  factory ClientStatisticsData.fromJson(Map<String, dynamic> json) {
    final recentRoutesJson = json['recentRoutes'] as List<dynamic>? ?? const [];

    return ClientStatisticsData(
      rideRequestCount: (json['rideRequestCount'] ?? json['riceRequestCount'] ?? 0) as int,
      courierRequestCount: (json['courierRequestCount'] ?? 0) as int,
      recentRoutes: recentRoutesJson
          .whereType<Map>()
          .map((route) => ClientRecentRoute.fromJson(Map<String, dynamic>.from(route)))
          .toList(),
    );
  }

  int get totalRequests => rideRequestCount + courierRequestCount;
}

class ClientRecentRoute {
  final String destinationLocation;
  final String originLocation;
  final DateTime? createdAt;
  final String requestType;

  const ClientRecentRoute({
    required this.destinationLocation,
    required this.originLocation,
    required this.createdAt,
    required this.requestType,
  });

  factory ClientRecentRoute.fromJson(Map<String, dynamic> json) {
    return ClientRecentRoute(
      destinationLocation: json['destinationLocation'] as String? ?? '',
      originLocation: json['originLocation'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      requestType: json['requestType'] as String? ?? 'RIDE',
    );
  }
}