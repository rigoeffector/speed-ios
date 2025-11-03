// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, prefer_is_empty

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../api/auth.service.dart';
import '../../../api/location.service.dart';
import '../../../connectivity/check.connectivity.dart';
import '../../../model/available.driver/available.driver.on.map.model.dart';
import '../../../states/available.driver.location/available_driver_location_bloc.dart';
import '../../../states/client.profile.data/client_profile_bloc.dart';
import '../../widgets/buttons/icon_button_normal.dart';
import '../../widgets/buttons/icon_button_outlined.dart';
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
      AvailableDriverLocationBloc(
          AvailableDriverLocationInitial(), LocationService());
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
  late AvailableDriverData motorbikerData;

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
  }

  @override
  void initState() {
    getCurrentUserInfo();
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    createRequestBloc = BlocProvider.of<CreateRequestBloc>(context);
    motorbikerData = AvailableDriverData();
    profileBloc = BlocProvider.of<ClientProfileBloc>(context);
    _availableDriverLocationBloc =
        BlocProvider.of<AvailableDriverLocationBloc>(context);
    _getCurrentLocation();
    loadCountryCode();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  checkIfNetworkIsAvailable() {
    networkUtils.checkConnectivity(context);
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent());
    profileBloc.add(FetchAllClientInformation(clientId: userId.toString()));
    checkIfNetworkIsAvailable();
  }

  void _handleRefresh() {
    _refreshController.forward(from: 0);
    _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent());
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
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent());
      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        sLat = currentPosition.latitude;
        sLng = currentPosition.longitude;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Error getting address: $e";
      });
    }
  }

  String distanceOriginDestination = "";
  String distancePrice = "0.0";
  String selectedUnitPrice = "1000";

  void calculateDistanceBtw(LatLng destination, LatLng source) {
    double distanceInMeters = Geolocator.distanceBetween(source.latitude,
        source.longitude, destination.latitude, destination.longitude);
    var distanceKm = distanceInMeters / 1000;
    if (kDebugMode) {
      print("DISTANCEMETERS: $distanceKm");
    }
    var totPrice = distanceKm * int.parse(selectedUnitPrice.toString());
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
  String? countryCode = "rw";

  String? jsonCode;
  loadCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    jsonCode = prefs.getString('currentCountryCode') ?? 'no';

    setState(() {
      countryCode = jsonCode;
    });
    if (countryCode.toString().toLowerCase() == 'rw') {
      selectedUnitPrice = "500";
    } else {
      selectedUnitPrice = "1000";
    }
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

  double distanceThreshold = 500.0;

  void _showMotorbikersBottomSheet(BuildContext context) {
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
                  // Header
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
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2, end: 0),
                  ),
                  // List
                  Expanded(
                    child: BlocConsumer<AvailableDriverLocationBloc,
                        AvailableDriverLocationState>(
                      listener: (context, state) {},
                      builder: (context, state) {
                        if (state is AvailableDriverLocationLoading) {
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
                            ],
                          ).animate().fadeIn(duration: 400.ms);
                        }

                        if (state is AvailableDriverLocationSuccess) {
                          List<AvailableDriverData> nearbyDrivers = state
                              .availableDriverOnMapModel.data!
                              .where((driver) {
                            if (driver.latitude != null &&
                                driver.longitude != null) {
                              double distance = calculateDistance(sLat, sLng,
                                  driver.latitude!, driver.longitude!);
                              return distance <= distanceThreshold;
                            }
                            return false;
                          }).toList();

                          if (nearbyDrivers.isEmpty) {
                            return Center(
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
                                    'Try again in a few moments',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .scale(delay: 200.ms),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: nearbyDrivers.length,
                            itemBuilder: (context, index) {
                              AvailableDriverData item = nearbyDrivers[index];
                              double distance = calculateDistance(sLat, sLng,
                                  item.latitude ?? 0, item.longitude ?? 0);

                              return _buildDriverCard(item, distance, index)
                                  .animate()
                                  .fadeIn(
                                      duration: 400.ms, delay: (50 * index).ms)
                                  .slideX(
                                      begin: 0.2,
                                      end: 0,
                                      delay: (50 * index).ms);
                            },
                          );
                        }
                        return const SizedBox.shrink();
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

  Widget _buildDriverCard(
      AvailableDriverData item, double distance, int index) {
    final isOnline = item.motorBiker!.status == 'ONLINE' ||
        item.motorBiker!.status == 'ACTIVE';

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
                        "${item.motorBiker!.fname ?? "------"} ${item.motorBiker!.lname ?? "------"}",
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
                          Text(
                            item.motorBiker!.phone ?? "------",
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
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
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
                  if (item.motorBiker?.motorType != null &&
                      item.motorBiker?.motorType != "null")
                    Row(
                      children: [
                        Icon(Icons.motorcycle,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          item.motorBiker!.motorType ?? '-------',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        item.motorBiker!.plateNumber ?? '-------',
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
                        distance < 1
                            ? '${(distance * 1000).toStringAsFixed(0)} m'
                            : '${distance.toStringAsFixed(2)} km',
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

  void _showRequestBottomSheet(
      BuildContext context, AvailableDriverData motorbike) {
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

  Widget _buildDriverInfoCard(AvailableDriverData motorbike) {
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
                  '${motorbike.motorBiker!.fname} ${motorbike.motorBiker!.lname}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Phone: ${motorbike.motorBiker!.phone}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              FlutterPhoneDirectCaller.callNumber(
                  motorbike.motorBiker!.phone.toString());
            },
            icon: const Icon(Icons.call),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(delay: 2000.ms, duration: 1500.ms),
        ],
      ),
    );
  }

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
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
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

  Widget _buildActionButtons(AvailableDriverData motorbike) {
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
                              motorBikerId: motorbike.motorBiker!.id!.toInt(),
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
                    IconButton(
                      onPressed: _handleRefresh,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RotationTransition(
                          turns: _refreshController,
                          child: const Icon(Icons.sync, color: Colors.white),
                        ),
                      ),
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
        "title": "RIDE",
        "image": "assets/images/motorcycle-white.png",
        "service": "Ride",
        "gradient": [Colors.blue, Colors.cyan],
      },
      {
        "title": "Courier",
        "image": "assets/images/shipping.png",
        "service": "Courier",
        "gradient": [Colors.orange, Colors.deepOrange],
      },
      {
        "title": "Tuk Tuk",
        "image": "assets/images/tuk-tuk.png",
        "service": "Tuk_Tuk",
        "gradient": [Colors.green, Colors.teal],
      },
      {
        "title": "RIFANI",
        "image": "assets/images/lifan.png",
        "service": "RIFANI",
        "gradient": [Colors.purple, Colors.deepPurple],
      },
      {
        "title": "Taxi Cab",
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
          _showMotorbikersBottomSheet(context);
          _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent());
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
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
                          width: 50,
                          height: 50,
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
                          fontSize: 16,
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

  void onBackPress() {
    context.safePop();
  }
}
