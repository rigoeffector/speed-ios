// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, prefer_is_empty

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/create_request_bloc.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../api/auth.service.dart';
import '../../../api/location.service.dart';
import '../../../connectivity/check.connectivity.dart';
import '../../../model/active_request_model.dart';
import '../../../model/available.driver/available.driver.on.map.model.dart';
import '../../../states/available.driver.location/available_driver_location_bloc.dart';
import '../../../states/client.profile.data/client_profile_bloc.dart';
import 'package:speed_ios/ui/screens/clients/cancel.request/cancel.screen.dart';

import '../../../states/requests/active_request_bloc.dart';
import '../../../states/requests/update/update_sent_request_status_bloc.dart';
import '../../widgets/lists/item_favorite_address_widget.dart';

class Home extends StatefulWidget {
  final String? refreshParam;

  const Home({Key? key, this.refreshParam}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  ClientProfileBloc profileBloc =
      ClientProfileBloc(ClientProfileInitial(), AuthService());
  CreateRequestBloc createRequestBloc =
      CreateRequestBloc(CreateRequestInitial(), AuthService());
  AvailableDriverLocationBloc _availableDriverLocationBloc =
      AvailableDriverLocationBloc(LocationService());
  ActiveRequestBloc _activeRequestBloc = ActiveRequestBloc(AuthService());

  UpdateSentRequestStatusBloc updateSentRequestStatusBloc =
      UpdateSentRequestStatusBloc(
          UpdateSentRequestStatusInitial(), AuthService());

  NetworkUtils networkUtils = NetworkUtils();
  late AnimationController _refreshController;

  String? userFullNames;
  String? userPhone;
  int? userId;
  String selectedService = '';
  TextEditingController currentLocationController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  int requestStep = 1;
  String? _currentAddress;
  late NearbyDriver motorbikerData;
  final _db = FirebaseDatabase.instance;
  getCurrentUserInfo() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userJson = sharedPreferences.getString("currentUser");
    Map<String, dynamic> userMap = jsonDecode(userJson!);
    setState(() {
      userFullNames =
          '${userMap['fname'] ?? '-------'} ${userMap['lname'] ?? '-------'}';
      userPhone = userMap['phone'];
      userId = userMap['id'];
    });

    _checkActiveRequest();
  }

  @override
  void initState() {
    getCurrentUserInfo();
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    updateSentRequestStatusBloc =
        BlocProvider.of<UpdateSentRequestStatusBloc>(context);

    createRequestBloc = BlocProvider.of<CreateRequestBloc>(context);
    _activeRequestBloc = BlocProvider.of<ActiveRequestBloc>(context);

    profileBloc = BlocProvider.of<ClientProfileBloc>(context);
    _availableDriverLocationBloc =
        BlocProvider.of<AvailableDriverLocationBloc>(context);
    _getCurrentLocation();
    loadCountryCode();
    _startPeriodicRefresh(); // Add this line
  }


    Future<void> _initPendingFirebaseTrip( String _requestId, String totalFare, String farePerKm, String totalDistance) async {
   
    await _db.ref('active_trips/$_requestId').set({
      'tripId': _requestId,
      'fare': {
        'totalFare':  totalFare,
        'farePerKm': farePerKm,
        'totalDistance':   totalDistance,
      }  
    });
  }

// Updated _checkActiveRequest method:

  Future<void> _checkActiveRequest() async {
    if (userId != null) {
      debugPrint('Checking active request for user ID: $userId');
      _activeRequestBloc.add(FetchActiveRequestEvent(clientId: userId!));
    }
  }

// Add these state variables in _HomeState class
  Timer? _refreshTimer;
  String? currentRequestId;
  String currentRequestStatus = '';
  ActiveRequestData? activeRequest;
  bool showRequestCard = false;

// Add this in dispose()
  @override
  void dispose() {
    _refreshController.dispose();
    _refreshTimer?.cancel(); // Add this line
    // _activeRequestBloc.close();
    super.dispose();
  }

// NEW METHOD: Start periodic refresh every 1 minute
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _handleRefresh();
        _checkActiveRequest();
      }
    });
  }

// NEW METHOD: Get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING_DRIVER':
        return Colors.orange;
      case 'APPROVED':
      case 'ASSIGNED':
      case 'ACCEPTED':
        return Colors.blue;
      case 'DRIVER_ARRIVING':
        return Colors.purple;
      case 'IN_PROGRESS':
      case 'ONGOING':
        return Colors.green;
      case 'COMPLETED':
        return Colors.teal;
      case 'REJECTED':
      case 'CANCELLED':
      case 'NO_DRIVER_AVAILABLE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

// NEW METHOD: Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.pending;
      case 'SEARCHING_DRIVER':
        return Icons.search;
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return Icons.person_pin_circle;
      case 'DRIVER_ARRIVING':
        return Icons.directions_car;
      case 'IN_PROGRESS':
      case 'ONGOING':
        return Icons.motorcycle;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.cancel;
      case 'NO_DRIVER_AVAILABLE':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

// NEW METHOD: Get status message
  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Your request is pending approval';
      case 'SEARCHING_DRIVER':
        return 'Searching for available driver...';
      case 'APPROVED':
        return 'Request approved! Finding driver...';
      case 'ASSIGNED':
        return 'Driver has been assigned to you';
      case 'ACCEPTED':
        return 'Driver accepted your request';
      case 'DRIVER_ARRIVING':
        return 'Driver is on the way to pick you up';
      case 'IN_PROGRESS':
      case 'ONGOING':
        return 'Your ride is in progress';
      case 'COMPLETED':
        return 'Ride completed successfully';
      case 'REJECTED':
        return 'Request was rejected';
      case 'CANCELLED':
        return 'Ride was cancelled';
      case 'NO_DRIVER_AVAILABLE':
        return 'No driver available at the moment';
      default:
        return 'Status: $status';
    }
  }

  checkIfNetworkIsAvailable() {
    networkUtils.checkConnectivity(context);
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch if we have valid coordinates
    if (sLat != 0.0 && sLng != 0.0) {
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent(
        latitude: sLat,
        longitude: sLng,
        radiusKm: distanceThreshold,
      ));
    }
    profileBloc.add(FetchAllClientInformation(clientId: userId.toString()));
    checkIfNetworkIsAvailable();
  }

  void _handleRefresh() {
    _refreshController.forward(from: 0);
    if (sLat != 0.0 && sLng != 0.0) {
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent(
        latitude: sLat,
        longitude: sLng,
        radiusKm: distanceThreshold,
      ));
    }
    _checkActiveRequest();
  }

  void _trackRide(BuildContext context, ActiveRequestData? request) {
    if (request != null) {
      debugPrint("Request ID: ${request.id}");
      context.safeGoNamed(clientDirections, params: {
        'requestId': request.id.toString(),
        'originLocation': request.originLocation.toString(),
        'destinationLocation': request.destinationLocation.toString(),
        'clientNames': '${request.client!.fname} ${request.client!.fname}',
        'clientPhone': '${request.client!.phone}',
        'driverName': '${request.driverName}',
        'driverPhone': '${request.driverPhone}',
      });
    }
  }

  void _cancelRide() {
    if (activeRequest != null) {
      // cancelRequestBloc.add(CancelRequestEvent(requestId: activeRequest!.requestId!));
    }
  }

  void _callDriver() {
    if (activeRequest != null) {
      FlutterPhoneDirectCaller.callNumber(
          activeRequest!.motorBiker!.phone.toString());
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Location services are disabled."),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Location permissions are denied."),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Location permissions are permanently denied."),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    locatePosition(position);
  }

  void locatePosition(Position currentPosition) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];
      print("/////////////////////// place //////////////////");
      print(place);
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: distanceThreshold));
      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        sLat = currentPosition.latitude;
        sLng = currentPosition.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = "Error getting address: $e";
      });
    }
  }

  String distanceOriginDestination = "";
  String distancePrice = "0.0";
  String selectedUnitPrice = "750";

  // void calculateDistanceBtw(LatLng destination, LatLng source) {
  //   double distanceInMeters = Geolocator.distanceBetween(source.latitude,
  //       source.longitude, destination.latitude, destination.longitude);
  //   var distanceKm = distanceInMeters / 1000;
  //   if (kDebugMode) {
  //     print("DISTANCEMETERS: $distanceKm");
  //   }
  //   var totPrice = distanceKm * int.parse(selectedUnitPrice.toString());
  //   setState(() {
  //     distanceOriginDestination = distanceKm.toStringAsFixed(1);
  //     distancePrice = totPrice.toStringAsFixed(1);
  //   });

  //   if (kDebugMode) {
  //     print("DISTANCE $distanceOriginDestination");
  //     print("DISTPRICE $distancePrice");
  //   }
  // }

  void calculateDistanceBtw(LatLng destination, LatLng source) {
  double distanceInMeters = Geolocator.distanceBetween(
    source.latitude,
    source.longitude,
    destination.latitude,
    destination.longitude,
  );

  double distanceKm = (distanceInMeters / 1000 * 10).roundToDouble() / 10;
  double unitPrice = double.parse(selectedUnitPrice.toString());
  double totPrice = (distanceKm * unitPrice * 10).roundToDouble() / 10;

  if (kDebugMode) {
    print("DISTANCE KM: $distanceKm");
  }

  setState(() {
    distanceOriginDestination = distanceKm.toStringAsFixed(1);
    distancePrice = totPrice.toStringAsFixed(1);
  });

  if (kDebugMode) {
    print("DISTANCE $distanceOriginDestination");
    print("DISTPRICE $distancePrice");
  }
}

  LatLng currentPosition = const LatLng(0, 0);
  LatLng destinationPosition = const LatLng(0, 0);
  LatLng originPosition = const LatLng(0, 0);

  String locationSelected = "";
  double dLat = 0.0, dLng = 0.0;
  double sLat = 0.0, sLng = 0.0;
  String? countryCode = "tz";

  String? jsonCode;
  loadCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    jsonCode = prefs.getString('currentCountryCode') ?? 'no';

    setState(() {
      countryCode = jsonCode;
    });
    selectedUnitPrice = "750";
    print("COUNTRY CODE $jsonCode");
  }

  void onSearchCity(BuildContext context) async {
    try {
      var place = await PlacesAutocomplete.show(
        offset: 0,
        radius: 2000,
        strictbounds: false,
        region: "$countryCode",
        context: context,
        mode: Mode.overlay,
        apiKey: dotenv.get('apiKey'),
        types: [],
        decoration: InputDecoration(
          hintText: "Search your destination",
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: InputBorder.none,
          hintStyle:
              GoogleFonts.poppins(fontSize: 11.0, fontWeight: FontWeight.w300),
        ),
        components: [
          Component(Component.country, '$countryCode'),
        ],
        hint: "Search Address",
        onError: (e) {
          print("ERRORS ${e.errorMessage}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Search error: ${e.errorMessage}"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );

      if (place != null) {
        try {
          final plist = GoogleMapsPlaces(
            apiKey: dotenv.get('apiKey'),
            apiHeaders: await const GoogleApiHeaders().getHeaders(),
          );
          String placeid = place.placeId ?? "0";
          final detail = await plist.getDetailsByPlaceId(placeid);
          final geometry = detail.result.geometry!;
          final lat = geometry.location.lat;
          final lng = geometry.location.lng;

          setState(() {
            dLat = lat;
            dLng = lng;
            destinationPosition = LatLng(dLat, dLng);
            locationSelected = place.description.toString();
          });

          LatLng dLatLng = LatLng(dLat, dLng);
          LatLng sLatLng = LatLng(sLat, sLng);
          print("Selected Location: $locationSelected");

          setState(() {
            calculateDistanceBtw(dLatLng, sLatLng);
            Navigator.pop(context, true);
            Future.delayed(const Duration(seconds: 1));
            _showRequestBottomSheet(context, motorbikerData);
          });
        } catch (e) {
          print("Error getting place details: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Failed to get location details. Please try again."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      print("Error in search: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Search failed. Please check your connection and try again."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void onSearchOriginCity(BuildContext context) async {
    try {
      var place = await PlacesAutocomplete.show(
        offset: 0,
        radius: 2000,
        strictbounds: false,
        region: "$countryCode",
        context: context,
        mode: Mode.overlay,
        apiKey: dotenv.get('apiKey'),
        types: [],
        decoration: InputDecoration(
          hintText: "Search your origin",
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: InputBorder.none,
          hintStyle:
              GoogleFonts.poppins(fontSize: 11.0, fontWeight: FontWeight.w300),
        ),
        components: [
          Component(Component.country, '$countryCode'),
        ],
        hint: "Search Address",
        onError: (e) {
          print("ERRORS ${e.errorMessage}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Search error: ${e.errorMessage}"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );

      if (place != null) {
        try {
          final plist = GoogleMapsPlaces(
            apiKey: dotenv.get('apiKey'),
            apiHeaders: await const GoogleApiHeaders().getHeaders(),
          );
          String placeid = place.placeId ?? "0";
          final detail = await plist.getDetailsByPlaceId(placeid);
          final geometry = detail.result.geometry!;
          final lat = geometry.location.lat;
          final lng = geometry.location.lng;

          setState(() {
            sLat = lat;
            sLng = lng;
            originPosition = LatLng(sLat, sLng);
            _currentAddress = place.description.toString();
          });

          LatLng dLatLng = LatLng(dLat, dLng);
          LatLng sLatLng = LatLng(sLat, sLng);
          print("Selected Origin Location: $_currentAddress");

          setState(() {
            calculateDistanceBtw(dLatLng, sLatLng);
            Navigator.pop(context, true);
            Future.delayed(const Duration(seconds: 1));
            _showRequestBottomSheet(context, motorbikerData);
          });
        } catch (e) {
          print("Error getting place details: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Failed to get location details. Please try again."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      print("Error in search: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Search failed. Please check your connection and try again."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double distanceThreshold = 3.0;

  void _showMotorbikersBottomSheet(BuildContext context) {
    // Fetch fresh data when opening
    if (sLat != 0.0 && sLng != 0.0) {
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent(
        latitude: sLat,
        longitude: sLng,
        radiusKm: distanceThreshold,
      ));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with refresh button
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getServiceIcon(selectedService),
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Drivers',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                '$selectedService Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        BlocBuilder<AvailableDriverLocationBloc,
                            AvailableDriverLocationState>(
                          builder: (context, state) {
                            final isLoading =
                                state is AvailableDriverLocationLoading;

                            return IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (sLat != 0.0 && sLng != 0.0) {
                                        _availableDriverLocationBloc.add(
                                          FetchAvailableDriverLocationEvent(
                                            latitude: sLat,
                                            longitude: sLng,
                                            radiusKm: distanceThreshold,
                                          ),
                                        );
                                      }
                                    },
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              color: primaryColor,
                            );
                          },
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2, end: 0),
                  ),

                  // Driver list
                  Expanded(
                    child: BlocConsumer<AvailableDriverLocationBloc,
                        AvailableDriverLocationState>(
                      listener: (context, state) {
                        if (state is AvailableDriverLocationError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'Retry',
                                textColor: Colors.white,
                                onPressed: () {
                                  if (sLat != 0.0 && sLng != 0.0) {
                                    _availableDriverLocationBloc.add(
                                      FetchAvailableDriverLocationEvent(
                                        latitude: sLat,
                                        longitude: sLng,
                                        radiusKm: distanceThreshold,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is AvailableDriverLocationLoading) {
                          return _buildLoadingState();
                        }

                        if (state is AvailableDriverLocationSuccess) {
                          return _buildDriversList(state, scrollController);
                        }

                        if (state is AvailableDriverLocationEmpty) {
                          return _buildEmptyState(state);
                        }

                        if (state is AvailableDriverLocationError) {
                          return _buildErrorState(state);
                        }

                        // Initial state
                        return _buildInitialDriversState();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Loading state
  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SpinKitDoubleBounce(
          color: primaryColor,
          size: 50,
        ),
        const SizedBox(height: 20),
        Text(
          'Finding nearby drivers...',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        if (sLat != 0.0 && sLng != 0.0)
          Text(
            'Searching at: ${sLat.toStringAsFixed(4)}, ${sLng.toStringAsFixed(4)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

// Drivers list with header info
  Widget _buildDriversList(
      AvailableDriverLocationSuccess state, ScrollController scrollController) {
    // NEW: Access drivers from the new structure
    final allDrivers = state.drivers; // This now returns List<NearbyDriver>

    // Filter nearby drivers using distanceKm from API
    List<NearbyDriver> nearbyDrivers = allDrivers.where((driver) {
      return driver.distanceKm <= distanceThreshold;
    }).toList();

    // Sort by distance (distance is already calculated by API)
    nearbyDrivers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (nearbyDrivers.isEmpty) {
      return _buildNoDriversNearby(state);
    }

    return Column(
      children: [
        // Info header with new metadata
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: primaryColor.withOpacity(0.05),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found ${state.driversCount} driver${state.driversCount == 1 ? '' : 's'} within ${distanceThreshold.toStringAsFixed(1)}km',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (state.hasMore)
                Icon(Icons.more_horiz, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                _getTimeAgo(state.lastUpdated),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Stale data warning
        if (state.isStale)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data may be outdated. Pull down to refresh.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Drivers list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: nearbyDrivers.length,
            itemBuilder: (context, index) {
              NearbyDriver item = nearbyDrivers[index];
              // Use the distance already calculated by the API
              double distance = item.distanceKm;

              return _buildDriverCard(item, distance, index)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                  .slideX(begin: 0.2, end: 0, delay: (50 * index).ms);
            },
          ),
        ),
      ],
    );
  }

// No drivers nearby
  Widget _buildNoDriversNearby(AvailableDriverLocationSuccess state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No drivers within ${distanceThreshold.toStringAsFixed(1)}km',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (state.driversCount > 0)
              Text(
                'Found ${state.driversCount} driver${state.driversCount == 1 ? '' : 's'} but they\'re further away',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Use the new ExpandSearchRadiusEvent
                _availableDriverLocationBloc
                    .add(const ExpandSearchRadiusEvent());
              },
              icon: const Icon(Icons.search),
              label: Text(
                'Search Wider Area',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
      ),
    );
  }

  Widget _buildDriverCard(NearbyDriver item, double distance, int index) {
    // NEW: Access properties from NearbyDriver model
    final isOnline = item.isOnline; // Use the getter
    final driverName = item.displayName; // Use the convenient getter
    final driverPhone = item.motorBikerPhone; // Or use specific field

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          // Note: Phone number not in NearbyDriver model
                          // You may need to adjust based on available fields
                          Text(
                            'Phone: ${item.motorBikerPhone}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          FlutterPhoneDirectCaller.callNumber(
                              driverPhone.toString());
                        },
                        icon: const Icon(Icons.call, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(6),
                        ),
                      )
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(delay: 2000.ms, duration: 1500.ms),
              ],
            ),
            const SizedBox(height: 12),

            // Vehicle info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.motorcycle, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        item.vehicleType,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (item.hasRating)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedRating,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Distance and request button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isOnline ? Colors.green : Colors.red,
                        isOnline
                            ? Colors.green.withOpacity(0.7)
                            : Colors.red.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.formattedDistance, // Use the convenient getter
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    motorbikerData = item;
                    _showRequestBottomSheet(context, item);
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(
                    'Request',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 200.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
// Empty state

  Widget _buildDriverInfoCard(NearbyDriver motorbike) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.05),
            primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED DRIVER',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  motorbike.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Phone: ${motorbike.motorBikerPhone}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (motorbike.hasRating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    motorbike.formattedRating,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

// 7. Update request creation in _buildActionButtons
  Widget _buildActionButtons(NearbyDriver motorbike) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.red),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: BlocConsumer<CreateRequestBloc, CreateRequestState>(
            listener: (context, state) {
              if (state is CreateRequestError) {
                showErrorAlert(state.message, context);
              }
              if (state is CreateRequestSuccess) {
                showSuccessAlert("REQUEST SENT SUCCESSFULLY", context);
                String requestID = state.myRequestsModel.data!.id.toString();

                _initPendingFirebaseTrip(requestID, distancePrice, selectedUnitPrice, distanceOriginDestination);
                Future.delayed(const Duration(milliseconds: 200), () {
                  context.safeGoNamed(myRequests);
                });
              }
            },
            builder: (context, state) {
              return ElevatedButton.icon(
                onPressed: state is CreateRequestLoading
                    ? null
                    : () {
                        if (locationSelected == '') {
                          showErrorAlert("Please select a location", context);
                        } else if (selectedService == '') {
                          showErrorAlert("Please select a service", context);
                        } else if (selectedUnitPrice == '') {
                          showErrorAlert("Please select a unit price", context);
                        } else {
                          createRequestBloc.add(
                            HandleCreateRequest(
                              motorBikerId:
                                  motorbike.motorBikerId, // Updated field
                              clientId: userId!.toInt(),
                              requestType: selectedService.toUpperCase(),
                              requestedTime: DateTime.now(),
                              originLocation: _currentAddress.toString(),
                              destinationLocation: locationSelected,
                              status: 'PENDING',
                            ),
                          );
                        }
                      },
                icon: state is CreateRequestLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  state is CreateRequestLoading ? 'Sending...' : 'Send Request',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AvailableDriverLocationEmpty state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No drivers available',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (sLat != 0.0 && sLng != 0.0) {
                  _availableDriverLocationBloc.add(
                    FetchAvailableDriverLocationEvent(
                      latitude: sLat,
                      longitude: sLng,
                      radiusKm: distanceThreshold,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
      ),
    );
  }

// Error state
  Widget _buildErrorState(AvailableDriverLocationError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (sLat != 0.0 && sLng != 0.0) {
                  _availableDriverLocationBloc.add(
                    FetchAvailableDriverLocationEvent(
                      latitude: sLat,
                      longitude: sLng,
                      radiusKm: distanceThreshold,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

// Initial state
  Widget _buildInitialDriversState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_searching,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Tap refresh to find drivers',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

// Helper method for time ago
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  final List<Map<String, dynamic>> favoriteAddresses = [
    {
      "id": "1",
      "title": "Home",
      "phone": "123456789",
      "address": "123 Main St, City, Country",
      "lat": -1.9565,
      "lng": 30.0644,
      "icon": "destination_icon.png",
    },
    {
      "id": "2",
      "title": "Office",
      "phone": "987654321",
      "address": "456 Office Rd, City, Country",
      "lat": -1.9470,
      "lng": 30.0919,
      "icon": "destination_icon.png",
    },
    {
      "id": "3",
      "title": "Friend's Place",
      "phone": "555555555",
      "address": "789 Friend Ave, City, Country",
      "lat": -1.9357,
      "lng": 30.0821,
      "icon": "destination_icon.png",
    },
  ];

  bool isPickUpAddressSelected = false;
  bool isPickUpAddress = false;
  bool isDestinationPicked = false;

  void _showFavoriteAddressesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 26),
          decoration: const BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'FAVORITE LOCATIONS',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteAddresses.length,
                  itemBuilder: (context, index) {
                    final address = favoriteAddresses[index];
                    return FavoriteAddress(
                      address: address['address'],
                      id: address['id'],
                      selectedId: "0",
                      title: address['title'],
                      phone: address['phone'],
                      lat: address['latitude'],
                      lng: address['longitude'],
                      icon: address['icon'],
                      onTap: () {
                        _onAddressTap(context, address);
                      },
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                        .slideX(begin: -0.2, end: 0, delay: (50 * index).ms);
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isPickUpAddress = false;
                        });
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                      label: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onAddressTap(BuildContext context, Map<String, dynamic> address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Selected: ${address['name']} (Lat: ${address['latitude']}, Long: ${address['longitude']})",
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {
      isPickUpAddressSelected = true;
      isPickUpAddress = false;
      _currentAddress = address['address'];
    });
    _showRequestBottomSheet(context, motorbikerData);
  }

  void _showRequestBottomSheet(BuildContext context, NearbyDriver motorbike) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getServiceIcon(selectedService),
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Request Details',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        '$selectedService Service',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showMotorbikersBottomSheet(context);
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: -0.2, end: 0),
                          const SizedBox(height: 24),

                          // Driver Card
                          _buildDriverInfoCard(motorbike)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 16),

                          // Search Pickup Button
                          _buildSearchButton(
                            icon: Icons.search,
                            label: 'Search Pickup Address',
                            onPressed: () => onSearchOriginCity(context),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          // Current Address
                          _buildAddressCard(
                            icon: Icons.my_location,
                            title: 'PICKUP LOCATION',
                            address: _currentAddress.toString(),
                            iconColor: Colors.blue,
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPickUpAddressSelected = false;
                                  _getCurrentLocation();
                                });
                              },
                              icon: Icon(
                                isPickUpAddressSelected
                                    ? Icons.close
                                    : Icons.location_searching_rounded,
                                color: isPickUpAddressSelected
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          // Destination
                          InkWell(
                            onTap: () => onSearchCity(context),
                            child: _buildAddressCard(
                              icon: CupertinoIcons.location_fill,
                              title: 'DESTINATION',
                              address: locationSelected.isNotEmpty
                                  ? locationSelected
                                  : "Tap to set destination",
                              iconColor: Colors.green,
                              isClickable: true,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 20),

                          // Distance and Price Info
                          if (locationSelected.isNotEmpty)
                            _buildPriceCard()
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 500.ms)
                                .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1, 1)),
                          const SizedBox(height: 24),

                          // Action Buttons
                          _buildActionButtons(motorbike)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildDriverInfoCard(NearbyDriver motorbike) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           primaryColor.withOpacity(0.05),
  //           primaryColor.withOpacity(0.02),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: primaryColor.withOpacity(0.2)),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [primaryColor, primaryColor.withOpacity(0.7)],
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: const Icon(Icons.person, color: Colors.white, size: 24),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'ASSIGNED DRIVER',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w400,
  //                   color: Colors.grey[600],
  //                 ),
  //               ),
  //               Text(
  //                 '${motorbike.motorBiker!.firstName} ${motorbike.motorBiker!.lastName}',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                   color: primaryColor,
  //                 ),
  //               ),
  //               Text(
  //                 'Phone: ${motorbike.motorBiker!.phone}',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w400,
  //                   color: Colors.grey[600],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         IconButton(
  //           onPressed: () {
  //             FlutterPhoneDirectCaller.callNumber(
  //                 motorbike.motorBiker!.phone.toString());
  //           },
  //           icon: const Icon(Icons.call),
  //           style: IconButton.styleFrom(
  //             backgroundColor: Colors.green,
  //             foregroundColor: Colors.white,
  //             padding: const EdgeInsets.all(12),
  //           ),
  //         )
  //             .animate(onPlay: (controller) => controller.repeat())
  //             .shimmer(delay: 2000.ms, duration: 1500.ms),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSearchButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required String title,
    required String address,
    required Color iconColor,
    Widget? trailing,
    bool isClickable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isClickable && address.contains('Tap')
                        ? Colors.grey[500]
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
          if (isClickable)
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPriceItem(
            icon: Icons.straighten,
            label: 'Distance',
            value: '$distanceOriginDestination Km',
            color: Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildPriceItem(
            icon: Icons.attach_money,
            label: 'Unit Price',
            value: selectedUnitPrice,
            color: Colors.orange,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildPriceItem(
            icon: Icons.payments,
            label: 'Total',
            value: distancePrice,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Widget _buildActionButtons(NearbyDriver motorbike) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: ElevatedButton.icon(
  //           onPressed: () => Navigator.of(context).pop(),
  //           icon: const Icon(Icons.close),
  //           label: Text(
  //             'Cancel',
  //             style: GoogleFonts.poppins(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.white,
  //             foregroundColor: Colors.red,
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               side: const BorderSide(color: Colors.red),
  //             ),
  //             elevation: 0,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         flex: 2,
  //         child: BlocConsumer<CreateRequestBloc, CreateRequestState>(
  //           listener: (context, state) {
  //             if (state is CreateRequestError) {
  //               showErrorAlert(state.message, context);
  //             }
  //             if (state is CreateRequestSuccess) {
  //               showSuccessAlert("REQUEST SENT SUCCESSFULLY", context);
  //               Future.delayed(const Duration(milliseconds: 200), () {
  //                 context.safeGoNamed(myRequests);
  //               });
  //             }
  //           },
  //           builder: (context, state) {
  //             return ElevatedButton.icon(
  //               onPressed: state is CreateRequestLoading
  //                   ? null
  //                   : () {
  //                       if (locationSelected == '') {
  //                         showErrorAlert("Please select a location", context);
  //                       } else if (selectedService == '') {
  //                         showErrorAlert("Please select a service", context);
  //                       } else if (selectedUnitPrice == '') {
  //                         showErrorAlert("Please select a unit price", context);
  //                       } else {
  //                         createRequestBloc.add(
  //                           HandleCreateRequest(
  //                             motorBikerId: motorbike.motorBiker!.id!.toInt(),
  //                             clientId: userId!.toInt(),
  //                             requestType: selectedService.toUpperCase(),
  //                             requestedTime: DateTime.now(),
  //                             originLocation: _currentAddress.toString(),
  //                             destinationLocation: locationSelected,
  //                             status: 'PENDING',
  //                           ),
  //                         );
  //                       }
  //                     },
  //               icon: state is CreateRequestLoading
  //                   ? const SizedBox(
  //                       width: 20,
  //                       height: 20,
  //                       child: CircularProgressIndicator(
  //                         color: Colors.white,
  //                         strokeWidth: 2,
  //                       ),
  //                     )
  //                   : const Icon(Icons.send),
  //               label: Text(
  //                 state is CreateRequestLoading ? 'Sending...' : 'Send Request',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: primaryColor,
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 elevation: 0,
  //                 disabledBackgroundColor: primaryColor.withOpacity(0.5),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  IconData _getServiceIcon(String service) {
    switch (service.toUpperCase()) {
      case 'RIDE':
        return Icons.motorcycle;
      case 'COURIER':
        return Icons.delivery_dining;
      case 'TUK_TUK':
        return Icons.local_taxi;
      case 'RIFANI':
        return Icons.electric_bike;
      case 'TAXICAB':
        return Icons.local_taxi;
      case 'TRUCK':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: primaryColor,
      elevation: 0,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome,',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$userFullNames',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          ListTile(
            leading: const Icon(Icons.request_page, color: Colors.white),
            title: Text(
              'My Requests',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.safeGoNamed(myRequests);
            },
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideX(begin: -0.2, end: 0),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                context.safeGoNamed(splash);
              },
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: primaryColor,
        drawer: _buildDrawer(context),
        body: Stack(
          children: [
            // Background Gradient Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.9),
                      primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Background Pattern Layer
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "assets/images/backparttern.png",
                  fit: BoxFit.cover,
                  color: Colors.white,
                  colorBlendMode: BlendMode.overlay,
                ),
              ),
            ),
            // Main Content with SliverAppBar
            CustomScrollView(
              slivers: [
                // Elegant SliverAppBar
                SliverAppBar(
                  expandedHeight: 160.0,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu, color: Colors.white),
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [
                    // Refresh button with BLoC loading indicator
                    BlocBuilder<ActiveRequestBloc, ActiveRequestState>(
                      builder: (context, state) {
                        final isLoading = state is ActiveRequestLoading;

                        return IconButton(
                          onPressed: isLoading ? null : _handleRefresh,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withOpacity(isLoading ? 0.1 : 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : RotationTransition(
                                    turns: _refreshController,
                                    child: const Icon(Icons.sync,
                                        color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideX(begin: -0.2, end: 0),
                              const SizedBox(height: 4),
                              Text(
                                '$userFullNames',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 100.ms)
                                  .slideX(begin: -0.2, end: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    // title: Text(
                    //   'Gerayo Amahoro Speed',
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.white,
                    //   ),
                    // ),
                  ),
                ),
                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          BlocBuilder<ActiveRequestBloc, ActiveRequestState>(
                            builder: (context, state) {
                              if (state is ActiveRequestLoading &&
                                  !showRequestCard) {
                                // Show loading skeleton
                                return _buildLoadingSkeleton();
                              }

                              if (state is ActiveRequestSuccess) {
                                return _buildRequestStatusCard(
                                    state.activeRequestModel);
                              }

                              return const SizedBox.shrink();
                            },
                          ),

                          // Section Header
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Choose Your Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            'Select a service to get started',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 5),
                          // Services Grid
                          _buildServiceGrid(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.95),
                primaryColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Text(
              "Powered by Besoft & BePay ltd",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      {
        "title": "Bodaboda",
        "image": "assets/images/motorcycle-white.png",
        "service": "Ride",
        "gradient": [Colors.blue, Colors.cyan],
      },
      {
        "title": "Delivery Package",
        "image": "assets/images/shipping.png",
        "service": "Courier",
        "gradient": [Colors.orange, Colors.deepOrange],
      },
      {
        "title": "Bajaji",
        "image": "assets/images/tuk-tuk.png",
        "service": "Tuk_Tuk",
        "gradient": [Colors.green, Colors.teal],
      },
      {
        "title": "Deliveru TukTuk",
        "image": "assets/images/lifan.png",
        "service": "RIFANI",
        "gradient": [Colors.purple, Colors.deepPurple],
      },
      {
        "title": "Taxi",
        "image": "assets/images/taxi_cab.png",
        "service": "TaxiCab",
        "gradient": [Colors.amber, Colors.orange],
      },
      {
        "title": "Truck",
        "image": "assets/images/delivery.png",
        "service": "Truck",
        "gradient": [Colors.red, Colors.pink],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          title: service['title'] as String,
          image: service['image'] as String,
          serviceKey: service['service'] as String,
          gradientColors: service['gradient'] as List<Color>,
          index: index,
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String image,
    required String serviceKey,
    required List<Color> gradientColors,
    required int index,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedService = serviceKey;
          });
          // Ensure we have valid location before showing drivers
          if (sLat == 0.0 || sLng == 0.0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Getting your location...'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            _getCurrentLocation().then((_) {
              if (sLat != 0.0 && sLng != 0.0) {
                _showMotorbikersBottomSheet(context);
              }
            });
          } else {
            _showMotorbikersBottomSheet(context);
          }
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Shimmer overlay effect (smaller)
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content with reduced padding
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon container (smaller)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          image,
                          width: 45,
                          height: 45,
                          color: Colors.white,
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 2000.ms,
                            delay: (500 * index).ms,
                            color: Colors.white.withOpacity(0.3),
                          ),
                      const SizedBox(height: 12),
                      // Title (adjusted font size)
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle (smaller)
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 8,
                      //     vertical: 2,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white.withOpacity(0.2),
                      //     borderRadius: BorderRadius.circular(6),
                      //   ),
                      //   child: Text(
                      //     'Available',
                      //     style: GoogleFonts.poppins(
                      //       fontSize: 9,
                      //       fontWeight: FontWeight.w500,
                      //       color: Colors.white.withOpacity(0.9),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: (100 * index).ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 500.ms,
          delay: (100 * index).ms,
          curve: Curves.easeOutBack,
        )
        .then()
        .shimmer(
          duration: 1500.ms,
          delay: 2000.ms,
          color: Colors.white.withOpacity(0.1),
        );
  }

  Widget _buildRequestStatusCard(ActiveRequestModel activeRequestModel) {
    final activeRequest = activeRequestModel.data;
    final currentRequestStatus = activeRequestModel.data?.status;
    // if (!showRequestCard || activeRequest == null) {
    //   return const SizedBox.shrink();
    // }

    final statusColor = _getStatusColor(currentRequestStatus!);
    final statusIcon = _getStatusIcon(currentRequestStatus!);
    final statusMessage = _getStatusMessage(currentRequestStatus!);
    final isActive = [
      'PENDING',
      'SEARCHING_DRIVER',
      'APPROVED',
      'ASSIGNED',
      'ACCEPTED',
      'DRIVER_ARRIVING',
      'IN_PROGRESS',
      'ONGOING'
    ].contains(currentRequestStatus.toUpperCase());

    // Extract driver and client info
    final driverName = activeRequest?.motorBiker?.firstName ??
        '${activeRequest?.motorBiker?.fullName ?? ''}'.trim();
    final driverPhone = activeRequest?.motorBiker?.phone ?? 'N/A';
    final plateNumber = activeRequest?.motorBiker?.plateNumber ?? 'N/A';
    final motorType = activeRequest?.motorType ??
        activeRequest?.motorBiker?.motorType ??
        activeRequest?.requestType ??
        'N/A';
    final driverStatus =
        activeRequest?.motorBiker?.isActive ?? false ? 'ONLINE' : 'OFFLINE';
    final priorityLevel = activeRequest?.priorityLevel ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // statusColor.withOpacity(0.03),
            Colors.white,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Animated background pattern
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(duration: 2000.ms)
                  .then()
                  .fadeOut(duration: 2000.ms),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor,
                              statusColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(delay: 2000.ms, duration: 1500.ms),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Request',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentRequestStatus.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                                  .animate(
                                      onPlay: (controller) =>
                                          controller.repeat())
                                  .fadeIn(duration: 1000.ms)
                                  .then()
                                  .fadeOut(duration: 1000.ms),
                              const SizedBox(width: 6),
                              Text(
                                'Active',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.1),
                          statusColor.withOpacity(0.3),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Message
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isActive)
                        Expanded(
                            child: _buildActionButton(currentRequestStatus,
                                statusColor, activeRequest!)),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(
        begin: -0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack);
  }

// NEW METHOD: Build loading skeleton for request card
  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                            duration: 1500.ms,
                            color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                            duration: 1500.ms,
                            color: Colors.white.withOpacity(0.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // Widget _buildActionButton(
  //     String status, Color statusColor, ActiveRequestData request) {
  //   switch (status.toUpperCase()) {
  //     case "PENDING":
  //     case "SEARCHING_DRIVER":
  //       return _ActionButton(
  //         icon: Icons.refresh,
  //         label: "Refresh",
  //         color: statusColor,
  //         request: request,
  //         onPressed: _handleRefresh,
  //       );

  //     case "APPROVED":
  //       return BlocConsumer<UpdateSentRequestStatusBloc,
  //           UpdateSentRequestStatusState>(
  //         listener: (context, state) {
  //           if (state is UpdateSentRequestStatusSuccess) {
  //             showSuccessAlert(
  //               state.updateSentRequestModel.message.toString(),
  //               context,
  //             );
  //             _handleRefresh();
  //           }
  //           if (state is UpdateSentRequestStatusError) {
  //             showErrorAlert(state.message.toString(), context);
  //           }
  //         },
  //         builder: (context, state) {
  //           return _ActionButton(
  //             icon: Icons.cancel_outlined,
  //             label: 'Cancel',
  //             color: redColor,
  //             request: request,
  //             onPressed: () {
  //               _showCancelBottomSheet(context, request.id!.toInt());
  //             },
  //           );
  //         },
  //       );

  //     case "ASSIGNED":
  //     case "ACCEPTED":
  //     case "DRIVER_ARRIVING":
  //       return _ActionButton(
  //         icon: Icons.call,
  //         label: "Call Driver",
  //         color: Colors.green,
  //         request: request,
  //         onPressed: _callDriver,
  //       );

  //     case "IN_PROGRESS":
  //     case "ONGOING":
  //       return _ActionButton(
  //         icon: Icons.location_searching_rounded,
  //         label: "Track Ride",
  //         color: Colors.orange,
  //         request: request,
  //         onPressed: () => _trackRide(context, request),
  //       );

  //     default:
  //       return const SizedBox.shrink();
  //   }
  // }

  Widget _buildActionButton(
  String status,
  Color statusColor,
  ActiveRequestData request,
) {
  switch (status.toUpperCase()) {
    case "PENDING":
    case "SEARCHING_DRIVER":
      return _ActionButton(
        icon: Icons.refresh,
        label: "Refresh",
        color: statusColor,
        request: request,
        onPressed: _handleRefresh,
      );

    case "APPROVED":
  return Row(
    children: [
      Expanded(
        child: BlocConsumer<UpdateSentRequestStatusBloc,
            UpdateSentRequestStatusState>(
          listener: (context, state) {
            if (state is UpdateSentRequestStatusSuccess) {
              showSuccessAlert(
                state.updateSentRequestModel.message.toString(),
                context,
              );
              _handleRefresh();
            }
            if (state is UpdateSentRequestStatusError) {
              showErrorAlert(state.message.toString(), context);
            }
          },
          builder: (context, state) {
            return _ActionButton(
              icon: Icons.cancel_outlined,
              label: "Cancel",
              color: redColor,
              request: request,
              onPressed: () {
                _showCancelBottomSheet(
                  context,
                  request.id!.toInt(),
                );
              },
            );
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ActionButton(
          icon: Icons.location_searching_rounded,
          label: "Track Ride",
          color: Colors.orange,
          request: request,
          onPressed: () => _trackRide(context, request),
        ),
      ),
    ],
  );
  case "ASSIGNED":
    case "ACCEPTED":
    case "DRIVER_ARRIVING":
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.call,
              label: "Call Driver",
              color: Colors.green,
              request: request,
              onPressed: _callDriver,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.location_searching_rounded,
              label: "Track Ride",
              color: Colors.orange,
              request: request,
              onPressed: () => _trackRide(context, request),
            ),
          ),
        ],
      );

    case "IN_PROGRESS":
    case "ONGOING":
      return _ActionButton(
        icon: Icons.location_searching_rounded,
        label: "Track Ride",
        color: Colors.orange,
        request: request,
        onPressed: () => _trackRide(context, request),
      );

    default:
      return const SizedBox.shrink();
  }
}

  // Add this new method to show the cancel bottom sheet
  void _showCancelBottomSheet(BuildContext context, int requestId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CancelRequestBottomSheet(
            onConfirmCancel: (String reason) {
              // Show final confirmation dialog
              _showFinalConfirmation(context, requestId, reason);
            },
          ),
        );
      },
    );
  }

// Add this method for final confirmation
  void _showFinalConfirmation(
      BuildContext context, int requestId, String reason) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Cancellation',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel this request?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            BlocBuilder<UpdateSentRequestStatusBloc,
                UpdateSentRequestStatusState>(
              builder: (context, state) {
                final isLoading = state is UpdateSentRequestStatusLaoding;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          // Call the bloc to cancel the request
                          updateSentRequestStatusBloc.add(
                            HandleUpdateStatus(
                              requestId: requestId.toString(),
                              status: 'CANCELLED',
                              cancellationReason: reason,
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Yes, Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ]
              .animate(interval: 50.ms)
              .fadeIn(duration: 200.ms, delay: 200.ms)
              .slideX(begin: 0.2, end: 0),
        );
      },
    );
  }

  void onBackPress() {
    context.safePop();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ActiveRequestData request;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.request,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color),
        ),
        elevation: 0,
      ),
    );
  }
}
