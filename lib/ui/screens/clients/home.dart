// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, prefer_is_empty

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/create_request_bloc.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:speed_ios/utils/notifiers.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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

class _HomeState extends State<Home> {
  ClientProfileBloc profileBloc =
      ClientProfileBloc(ClientProfileInitial(), AuthService());
  CreateRequestBloc createRequestBloc =
      CreateRequestBloc(CreateRequestInitial(), AuthService());
  AvailableDriverLocationBloc _availableDriverLocationBloc =
      AvailableDriverLocationBloc(
          AvailableDriverLocationInitial(), LocationService());
  NetworkUtils networkUtils = NetworkUtils();
  String? userFullNames;
  String? userPhone;
  int? userId;
  String selectedService =
      ''; // Store the selected service type (Ride or Courier)
  TextEditingController currentLocationController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  int requestStep = 1;
  String? _currentAddress; // For storing the current address
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
    createRequestBloc = BlocProvider.of<CreateRequestBloc>(context);
    motorbikerData = AvailableDriverData();
    profileBloc = BlocProvider.of<ClientProfileBloc>(context);
    _availableDriverLocationBloc =
        BlocProvider.of<AvailableDriverLocationBloc>(context);
    _getCurrentLocation(); // Get current location on startup
    loadCountryCode();
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

  // Function to get the current location using the geolocator plugin
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Convert position to human-readable address
    locatePosition(position);
  }

  // Function to convert latitude and longitude into address
  void locatePosition(Position currentPosition) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    // Reverse geocoding to get address
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];
      print("/////////////////////// place //////////////////");
      print(place);
      _availableDriverLocationBloc.add(FetchAvailableDriverLocationEvent());
      // street, city, state, postal_code, country
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

  // Dummy list of motorbikers for demonstration

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
    // var totPrice = distanceKm;
    setState(() {
      distanceOriginDestination = distanceKm.toStringAsFixed(1);
      distancePrice = totPrice.toStringAsFixed(1);
    });

    if (kDebugMode) {
      print("DISTANCE $distanceOriginDestination"); //d
      print("DISTPRICE $distancePrice");
    } //d
  }

  LatLng currentPosition = const LatLng(0, 0); // default position
  LatLng destinationPosition = const LatLng(0, 0); // selected place
  LatLng originPosition = const LatLng(0, 0); // selected place

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
    var place = await PlacesAutocomplete.show(
      offset: 0,
      radius: 2000,
      strictbounds: false,
      region: "$countryCode", // Update with your country code
      context: context,
      mode: Mode.overlay,
      apiKey: dotenv.get('apiKey'),
      types: [],
      decoration: InputDecoration(
        hintText: "Search your destination",
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: InputBorder.none,
        hintStyle:
            GoogleFonts.poppins(fontSize: 11.0, fontWeight: FontWeight.w300),
      ),
      components: [
        Component(
            Component.country, '$countryCode'), // Update with your country code
      ],
      hint: "Search Address",
      onError: (e) {
        print("ERRORS ${e.errorMessage}");
      },
    );

    if (place != null) {
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
    }
  }

  void onSearchOriginCity(BuildContext context) async {
    var place = await PlacesAutocomplete.show(
      offset: 0,
      radius: 2000,
      strictbounds: false,
      region: "$countryCode", // Update with your country code
      context: context,
      mode: Mode.overlay,
      apiKey: dotenv.get('apiKey'),
      types: [],
      decoration: InputDecoration(
        hintText: "Search your origin",
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: InputBorder.none,
        hintStyle:
            GoogleFonts.poppins(fontSize: 11.0, fontWeight: FontWeight.w300),
      ),
      components: [
        Component(
            Component.country, '$countryCode'), // Update with your country code
      ],
      hint: "Search Address",
      onError: (e) {
        print("ERRORS ${e.errorMessage}");
      },
    );

    if (place != null) {
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
        originPosition =
            LatLng(sLat, sLng); // destinationPosition = LatLng(dLat, dLng);

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
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of the Earth in kilometers
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double distanceThreshold = 500.0; // 5 kilometers range

  // Function to show bottom sheet with motorbikers list
  void _showMotorbikersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Select Nearby $selectedService Service',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              BlocConsumer<AvailableDriverLocationBloc,
                  AvailableDriverLocationState>(
                listener: (context, state) {
                  // TODO: implement listener
                },
                builder: (context, state) {
                  if (state is AvailableDriverLocationLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Loading nearby $selectedService Service',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 20),
                                const SpinKitDoubleBounce(
                                  color: primaryColor,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is AvailableDriverLocationSuccess) {
                    List<AvailableDriverData> nearbyDrivers =
                        state.availableDriverOnMapModel.data!.where((driver) {
                      if (driver.latitude != null && driver.longitude != null) {
                        double distance = calculateDistance(
                            sLat, sLng, driver.latitude!, driver.longitude!);
                        // Check if the requestedTime is close to now
                        return distance <= distanceThreshold;
                      }
                      return false;
                    }).toList();

                    if (nearbyDrivers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 70.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.grey, width: 2),
                                ),
                                padding: const EdgeInsets.all(
                                    20), // adjust padding for icon size
                                child: const Icon(
                                  Icons.inbox, // use any icon you prefer
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(
                                  height: 16), // space between icon and text
                              Text(
                                'No Available Driver found',
                                style: GoogleFonts.poppins(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView.builder(
                        itemCount: nearbyDrivers.length,
                        itemBuilder: (context, index) {
                          AvailableDriverData item = nearbyDrivers[index];
                          final motorbiker = item;

                          // Calculate the distance between user and driver
                          double distance = calculateDistance(sLat, sLng,
                              item.latitude ?? 0, item.longitude ?? 0);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: whiteColor1,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 188, 188, 188)
                                          .withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item.motorBiker!.fname ?? "------"} ${item.motorBiker!.lname ?? "------"}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Phone: ${item.motorBiker!.phone ?? "------"}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 4, bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: whiteColor1,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Visibility(
                                          visible: item.motorBiker?.motorType !=
                                                  null ||
                                              item.motorBiker?.motorType !=
                                                  "null",
                                          child: Text(
                                              'Motor: ${item.motorBiker?.motorType != null || item.motorBiker?.motorType != "null" ? item.motorBiker?.motorType : '-------'}'),
                                        ),
                                        Text(
                                            'Plate: ${item.motorBiker!.plateNumber ?? '-------'}'),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color:
                                              motorbiker.motorBiker!.status ==
                                                          'ONLINE' ||
                                                      motorbiker.motorBiker!
                                                              .status ==
                                                          'ACTIVE'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        child: Text(
                                          distance < 1
                                              ? '${(distance * 1000).toStringAsFixed(0)} m' // Converts to meters if distance is under 1 km
                                              : '${distance.toStringAsFixed(2)} km', // Displays in km if distance is 1 km or more
                                          style: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                          motorbikerData = item;
                                          _showRequestBottomSheet(
                                              context, item);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 18),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.green,
                                                  width: 1)),
                                          child: Text(
                                            'Request  ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ],
          ),
        );
      },
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
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'FAVORITE LOCATION',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryColor),
                ),
              ),
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
                        // Action when the item is tapped
                        _onAddressTap(context, address);
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  MyOutlineButton(
                    title: "Close Favorite",
                    icon: Icons.close,
                    titleColor: redColor,
                    backgroundColor: whiteColor,
                    width: 100,
                    onTap: () {
                      setState(() {
                        isPickUpAddress = false;
                      });
                      Navigator.of(context).pop();
                    },
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
    // Perform an action when an address is tapped
    // For example, show a snackbar with the address name and coordinates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Selected: ${address['name']} (Lat: ${address['latitude']}, Long: ${address['longitude']})",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {
      // sLat = address['latitude'];
      // sLng = address['longitude'];
      isPickUpAddressSelected = true;
      isPickUpAddress = false;
      _currentAddress = address['address'];
    });
    _showRequestBottomSheet(context, motorbikerData);
    // Close the bottom sheet

    // You could also navigate to another screen or perform other actions here
    // Navigator.push(context, MaterialPageRoute(builder: (context) => YourNextScreen()));
  }

  // Function to show bottom sheet with request
  void _showRequestBottomSheet(
      BuildContext context, AvailableDriverData motorbike) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false, // Allows scrolling if the content exceeds the height
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                  color: whiteColor,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            '$selectedService Request',
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: primaryColor),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showMotorbikersBottomSheet(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close),
                          ),
                        ), // Navigate to motorbike details
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: whiteColor0,
                        border: Border.all(
                          color: whiteColor1,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width - 200,
                                    child: Text(
                                      "DRIVER / MOTOBIKER",
                                      maxLines: 1,
                                      // softWrap: false,
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w300,
                                          color: primaryColor,
                                          fontSize: 10),
                                    )),
                                Text(
                                  '${motorbike.motorBiker!.fname} ${motorbike.motorBiker!.lname}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Phone: ${motorbike.motorBiker!.phone}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: InkWell(
                          onTap: () {
                            FlutterPhoneDirectCaller.callNumber(
                                motorbike.motorBiker!.phone.toString());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.call, color: orangeColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Checkbox for Favorite Pickup Address
                          Visibility(
                            visible: false,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isPickUpAddress,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      isPickUpAddress = newValue!;
                                      // if (isPickUpAddress) {
                                      //   _showFavoriteAddressesBottomSheet(
                                      //       context);
                                      // }

                                      //Remove later

                                      onSearchOriginCity(context);
                                    });
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      // isPickUpAddress = !isPickUpAddress;
                                      // if (isPickUpAddress) {
                                      //   _showFavoriteAddressesBottomSheet(
                                      //       context);
                                      // }

                                      //Remove later
                                      onSearchOriginCity(context);
                                    });
                                  },
                                  child: const Text(
                                    "Favorite Pickup",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors
                                          .blue, // Customize color if needed
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search Pickup Address Button
                          ElevatedButton.icon(
                            onPressed: () {
                              // Action for searching pickup addresses
                              onSearchOriginCity(context);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text("Search Pickup"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor:
                                  Colors.transparent, // White text color
                              elevation: 0, // No elevation

                              fixedSize: const Size(200,
                                  30), // Set button height to 50 and width to fill
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: whiteColor,
                          border: Border.all(color: primaryColor, width: 1),
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 280,
                                  child: Text(
                                    "CURRENT ADDRESS",
                                    maxLines: 1,
                                    // softWrap: false,
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w300,
                                        fontSize: 10),
                                  )),
                              SizedBox(
                                  width: 280,
                                  child: Text(
                                    _currentAddress.toString(),
                                    maxLines: 2,
                                    // softWrap: false,
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  )),
                            ],
                          ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  isPickUpAddressSelected = false;
                                  _getCurrentLocation();
                                });
                              },
                              icon: isPickUpAddressSelected
                                  ? const Icon(
                                      Icons.close,
                                      color: redColor,
                                    )
                                  : const Icon(
                                      Icons.location_searching_rounded,
                                      color: greenColor,
                                    ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            onSearchCity(context);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(width: 1.2, color: greyColor1)),
                            margin: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 13),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.placemark,
                                      color: greyColor1,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                        child: Text(
                                          locationSelected != ""
                                              ? locationSelected
                                              : "Set your destination ",
                                          overflow: TextOverflow.clip,
                                          maxLines: 3,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Visibility(
                      visible: locationSelected != '',
                      child: Container(
                        decoration: BoxDecoration(
                            color: whiteColor1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1, color: whiteColor1)),
                        margin: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Distance",
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.fade,
                                  style: GoogleFonts.poppins(
                                      color: greyColor,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12),
                                ),
                                Text(
                                  "$distanceOriginDestination Km",
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.fade,
                                  style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                )
                              ],
                            ),
                            Visibility(
                              visible: locationSelected != '',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Unit Price",
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.fade,
                                    style: GoogleFonts.poppins(
                                        color: greyColor,
                                        fontWeight: FontWeight.w300,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    "$selectedUnitPrice",
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.fade,
                                    style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  )
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Price",
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.fade,
                                  style: GoogleFonts.poppins(
                                      color: greyColor,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12),
                                ),
                                Text(
                                  "$distancePrice",
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.fade,
                                  style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          MyOutlineButton(
                            title: "Cancel",
                            icon: Icons.close,
                            titleColor: redColor,
                            backgroundColor: whiteColor,
                            width: 100,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          BlocConsumer<CreateRequestBloc, CreateRequestState>(
                            listener: (context, state) {
                              if (state is CreateRequestError) {
                                showErrorAlert(state.message, context);
                              }

                              if (state is CreateRequestSuccess) {
                                // Close the bottom sheet
                                showSuccessAlert(
                                  "REQUEST SENT SUCCESSFULL",
                                  context,
                                );

                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
                                  context.safeGoNamed(myRequests);
                                });
                              }
                            },
                            builder: (context, state) {
                              return MyIconButton(
                                title: state is CreateRequestLoading
                                    ? 'Loading....'
                                    : "Send Request",
                                icon: Icons.local_taxi_rounded,
                                titleColor: whiteColor,
                                backgroundColor: primaryColor,
                                width: 100,
                                onTap: () {
                                  if (locationSelected == '') {
                                    showErrorAlert(
                                      "Please select a location",
                                      context,
                                    );
                                  } else if (selectedService == '') {
                                    showErrorAlert(
                                      "Please select a service",
                                      context,
                                    );
                                  } else if (selectedUnitPrice == '') {
                                    showErrorAlert(
                                      "Please select a unit price",
                                      context,
                                    );
                                  } else {
                                    createRequestBloc.add(
                                      HandleCreateRequest(
                                        motorBikerId:
                                            motorbike.motorBiker!.id!.toInt(),
                                        clientId: userId!.toInt(),
                                        requestType:
                                            selectedService.toUpperCase(),
                                        requestedTime: DateTime
                                            .now(), // Set the current time
                                        originLocation:
                                            _currentAddress.toString(),
                                        destinationLocation: locationSelected,
                                        status: 'PENDING',
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Function to build the Drawer
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: primaryColor,
      elevation: 0,
      child: Column(
        children: [
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 10), // Space between avatar and text
                  // Welcome Text and Name
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    width: 150,
                    decoration: const BoxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome,',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: Text(
                            '$userFullNames',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3, // Display the user's name
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.request_page,
              color: Colors.white,
            ),
            title: const Text(
              'My Requests',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.safeGoNamed(myRequests);
            },
          ),
          const Spacer(), // Pushes the logout button to the bottom
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onTap: () async {
              // Close drawer
              Navigator.pop(context);

              // Clear all shared preferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Navigate to the login or desired screen after clearing preferences
              context.safeGoNamed(
                  splash); // Replace 'login' with your login route name
            },
          ),
          const SizedBox(height: 20), // Adds some space at the bottom
        ],
      ),
    );
  }

  // final _firestore = FirebaseFirestore.instance;

  // void sendDriverNotification(String driverId, String title, String msg) async {
  //   DocumentSnapshot snap =
  //       await _firestore.collection("driverTokens").doc(driverId).get();
  //   String token = snap['token'];
  // }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: const Text("Speed", style: TextStyle(color: Colors.white),),
          actions: [
            IconButton(
              onPressed: () {
                // Handle request job action
                AppNavigation.navigateToRefreshHome(context);
              },
              icon: const Icon(
                Icons.sync,
                color: Colors.yellow,
                size: 40,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        drawer: _buildDrawer(context), // Add the Drawer here
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/backparttern.png",
                color: Colors.black.withOpacity(0.3), // Adjust opacity here
                colorBlendMode: BlendMode.srcATop,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              child: Container(
                color: primaryColorOverlay,
              ),
            ),
            // Main Content
            SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.only(left: 20.0),
                      child: Text(
                        'Welcome $userFullNames',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.only(left: 20.0),
                      child: const Text(
                        'Choose Service',
                        style: TextStyle(
                          fontSize: 38,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildServiceRow(context, [
                          {
                            "title": "RIDE",
                            "image": "assets/images/motorcycle-white.png",
                            "service": "Ride",
                          },
                          {
                            "title": "Courier / Delivery",
                            "image": "assets/images/shipping.png",
                            "service": "Courier",
                          },
                        ]),
                        const SizedBox(height: 20), // Space between buttons
                        _buildServiceRow(context, [
                          {
                            "title": "BAJAJ Tuk Tuk",
                            "image": "assets/images/tuk-tuk.png",
                            "service": "Tuk_Tuk",
                          },
                          {
                            "title": "RIFANI",
                            "image": "assets/images/lifan.png",
                            "service": "RIFANI",
                          },
                        ]),
                        const SizedBox(height: 20), // Space between buttons
                        _buildServiceRow(context, [
                          {
                            "title": "TAXI CAB",
                            "image": "assets/images/taxi_cab.png",
                            "service": "TaxiCab",
                          },
                          {
                            "title": "TRUCK",
                            "image": "assets/images/delivery.png",
                            "service": "Truck",
                          },
                        ]),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          color: primaryColor.withOpacity(0.9),
          height: 40,
          child: Center(
            child: Text(
              "Powerd by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: whiteColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceRow(
      BuildContext context, List<Map<String, String>> services) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: services.map((service) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: MediaQuery.of(context).size.width / 2 - 25,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              fixedSize: const Size(double.infinity, 150),
            ),
            onPressed: () {
              setState(() {
                selectedService = service['service']!;
              });
              _showMotorbikersBottomSheet(context);
              _availableDriverLocationBloc
                  .add(FetchAvailableDriverLocationEvent());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  service['image']!,
                  scale: 8,
                ),
                const SizedBox(height: 10),
                Text(
                  service['title']!,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // For navigation
  void onBackPress() {
    context.safePop(); // Uses the extension
  }
}
