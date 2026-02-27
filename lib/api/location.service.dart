import 'dart:convert';

import 'package:speed_ios/api/timeout.exception.dart';
import 'package:speed_ios/model/client.favorite.location.model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speed_ios/model/available.driver/available.driver.on.map.model.dart';
import 'package:speed_ios/model/nearby_driver_model.dart';

import '../model/client.location.model.dart';

class LocationService {
  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch nearby available drivers using the new API structure
  /// 
  /// Now returns AvailableDriverOnMapModel with nested data structure
  Future<AvailableDriverOnMapModel> fetchAvailableDriverLocation(
    double latitude,
    double longitude, [
    double radiusKm = 5.0,
    int limit = 50,
  ]) async {
    try {
      // Validate inputs
      if (latitude < -90 || latitude > 90) {
        throw ArgumentError('Latitude must be between -90 and 90');
      }
      if (longitude < -180 || longitude > 180) {
        throw ArgumentError('Longitude must be between -180 and 180');
      }
      if (radiusKm < 0.1 || radiusKm > 50.0) {
        throw ArgumentError('Radius must be between 0.1 and 50 km');
      }

      final uri = Uri.parse(
        '${dotenv.get('mainUrl')}/available-motors/online/nearby',
      ).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radiusKm': radiusKm.toString(),
        'limit': limit.toString(),
      });

      print('Fetching drivers from: $uri');

      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out after 15 seconds');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> results = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success - parse the new nested structure
        return AvailableDriverOnMapModel.fromJson(results);
      } else if (response.statusCode == 400) {
        // Bad request
        return AvailableDriverOnMapModel(
          message: results['message'] as String? ?? 'Bad request',
          success: false,
          data: NearbyDriversData(
            drivers: const [],
            count: 0,
            searchCenter: SearchCenter(
              latitude: latitude,
              longitude: longitude,
            ),
            radiusKm: radiusKm,
            hasMore: false,
          ),
        );
      } else if (response.statusCode == 404) {
        // No drivers found
        return AvailableDriverOnMapModel(
          message: results['message'] as String? ?? 'No drivers found',
          success: false,
          data: NearbyDriversData(
            drivers: const [],
            count: 0,
            searchCenter: SearchCenter(
              latitude: latitude,
              longitude: longitude,
            ),
            radiusKm: radiusKm,
            hasMore: false,
          ),
        );
      } else if (response.statusCode >= 500) {
        // Server error
        return _createErrorResponse(
          latitude,
          longitude,
          radiusKm,
          'Server error: ${response.statusCode}',
        );
      } else {
        // Other errors
        return _createErrorResponse(
          latitude,
          longitude,
          radiusKm,
          results['message'] as String? ?? 'Unknown error',
        );
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      return _createErrorResponse(
        latitude,
        longitude,
        radiusKm,
        'Request timeout. Please check your connection.',
      );
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      return _createErrorResponse(
        latitude,
        longitude,
        radiusKm,
        'Invalid response format from server',
      );
    } catch (e) {
      print('Error fetching available drivers: $e');
      return _createErrorResponse(
        latitude,
        longitude,
        radiusKm,
        'Failed to fetch drivers: ${e.toString()}',
      );
    }
  }

  /// Fetch drivers with automatic retry
  Future<AvailableDriverOnMapModel> fetchAvailableDriverLocationWithRetry(
    double latitude,
    double longitude, [
    double radiusKm = 5.0,
    int limit = 50,
    int maxRetries = 3,
  ]) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await fetchAvailableDriverLocation(
          latitude,
          longitude,
          radiusKm,
          limit,
        );
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          return _createErrorResponse(
            latitude,
            longitude,
            radiusKm,
            'Failed after $maxRetries attempts: ${e.toString()}',
          );
        }

        print('Retry $retryCount/$maxRetries after error: $e');
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    return _createErrorResponse(
      latitude,
      longitude,
      radiusKm,
      'Max retries exceeded',
    );
  }

  /// Create an error response with proper structure
  AvailableDriverOnMapModel _createErrorResponse(
    double latitude,
    double longitude,
    double radiusKm,
    String errorMessage,
  ) {
    return AvailableDriverOnMapModel(
      message: errorMessage,
      success: false,
      data: NearbyDriversData(
        drivers: const [],
        count: 0,
        searchCenter: SearchCenter(
          latitude: latitude,
          longitude: longitude,
        ),
        radiusKm: radiusKm,
        hasMore: false,
      ),
    );
  }

  // ============================================================================
  // EXISTING METHODS - UNCHANGED
  // ============================================================================

  Future<NearbyDriverModel> fetchNearbyDriveerLocationInfo(
    String latitude,
    String longitude,
    String radius,
    String paymentMethod,
  ) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/client/fetch_nearby_driver'),
      headers: headers,
      body: json.encode({
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'paymentMethod': paymentMethod.toString(),
      }),
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    } else if (response.statusCode == 400) {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    } else {
      NearbyDriverModel nearbyDriverModel = NearbyDriverModel.fromJson(results);
      return nearbyDriverModel;
    }
  }

  Future<CreateClientLocationModel> createClientFavoriteLocation(
    String latitude,
    String longitude,
    String clientId,
    String title,
    String address,
    String phone,
  ) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/client/save_favorite_location'),
      headers: headers,
      body: json.encode({
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'clientId': clientId.toString(),
        'title': title.toString(),
        'address': address.toString(),
        'phone': phone.toString(),
      }),
    );

    Map<String, dynamic> results = jsonDecode(response.body);

    print("SSAVE $results");
    if (response.statusCode == 200) {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    } else if (response.statusCode == 400) {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    } else {
      CreateClientLocationModel model =
          CreateClientLocationModel.fromJson(results);
      return model;
    }
  }

  Future<ClientFavoriteLocationModel> getClientFavoriteLocation(
    String clientId,
  ) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
      Uri.parse('${dotenv.get('mainUrl')}/client/fetch_favorite_location'),
      headers: headers,
      body: json.encode({
        'clientId': clientId.toString(),
      }),
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    } else if (response.statusCode == 400) {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    } else {
      ClientFavoriteLocationModel model =
          ClientFavoriteLocationModel.fromJson(results);
      return model;
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}

