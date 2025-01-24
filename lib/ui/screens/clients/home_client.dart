// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_normal.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_map_polyline_new/google_map_polyline_new.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../states/requests/update/update_sent_request_status_bloc.dart';
import '../../../utils/colors.dart';
import 'package:http/http.dart' as http;

class ClientDirections extends StatefulWidget {
  final String? requestId;
  final String? clientPhone;
  final String? clientNames;
  final String? destinationLocation;
  final String? originLocation;

  const ClientDirections(
      {super.key,
      this.requestId,
      this.clientPhone,
      this.clientNames,
      this.destinationLocation,
      this.originLocation});

  @override
  _ClientDirectionsState createState() => _ClientDirectionsState();
}

class _ClientDirectionsState extends State<ClientDirections> {
  GoogleMapController? _controllers;
  BitmapDescriptor? clientIcon;
  BitmapDescriptor? driverIcon;
  BitmapDescriptor? destinationIcon;
  final List<Marker> marker = [];
  final List<Circle> circle = [];
  Completer<GoogleMapController> controllerGoogleMapCompleter = Completer();
  UpdateSentRequestStatusBloc updateSentRequestStatusBloc =
      UpdateSentRequestStatusBloc(
          UpdateSentRequestStatusInitial(), AuthService());
  final List<Marker> _list = [];
  void setClientDriverMarkerIcons() async {
    clientIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0),
        "assets/images/location-pin.png");
    driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0),
        "assets/images/bike-pin.png");
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0),
        "assets/images/destination_icon.png");
  }

  String currentAddress = "";
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

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 15.6);
      _controllers!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      initialPosition =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      Placemark place = placemarks[0];
      if (mounted) {
        setState(() {
          currentAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";

          sLat = currentPosition.latitude;
          sLng = currentPosition.longitude;
        });
        getPickupWithAddress(currentAddress);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentAddress = "Error getting address: $e";
        });
      }
    }

    print("PASP $initialPosition");
  }

  // Dummy list of motorbikers for demonstration

  bool loading = false;

  LatLng initialPosition = const LatLng(0, 0); // default position
  LatLng destinationPosition = const LatLng(0, 0); // selected place
  String locationSelected = "";
  double dLat = 0.0, dLng = 0.0;
  double sLat = 0.0, sLng = 0.0;
  String? countryCode = "rw";

  int _polylineCount = 1;
  int _polylineRouteCount = 1;
  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  final GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: dotenv.get('apiKey'));

  //Polyline patterns
  List<List<PatternItem>> patterns = <List<PatternItem>>[
    <PatternItem>[], //line
    <PatternItem>[PatternItem.dash(30.0), PatternItem.gap(20.0)], //dash
    <PatternItem>[PatternItem.dot, PatternItem.gap(10.0)], //dot
    <PatternItem>[
      //dash-dot
      PatternItem.dash(30.0),
      PatternItem.gap(20.0),
      PatternItem.dot,
      PatternItem.gap(20.0)
    ],
  ];

  bool _loading = false;
  double calculateBearing(LatLng start, LatLng end) {
    final double startLat = start.latitude * (math.pi / 180);
    final double startLng = start.longitude * (math.pi / 180);
    final double endLat = end.latitude * (math.pi / 180);
    final double endLng = end.longitude * (math.pi / 180);

    final double dLng = endLng - startLng;
    final double x = math.sin(dLng) * math.cos(endLat);
    final double y = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final double bearing = math.atan2(x, y) * (180 / math.pi);
    return (bearing + 360) % 360; // Normalize to 0 - 360 degrees
  }

  Future<void> getCoordinatesFromAddress(String address) async {
    try {
      // Convert address to coordinates
      List<Location> locations = await locationFromAddress(address);

      // Extract latitude and longitude
      if (locations.isNotEmpty) {
        dLat = locations[0].latitude;
        dLng = locations[0].longitude;

        if (kDebugMode) {
          print('Latitude: $dLat, Longitude: $dLng');
        }

        _calculateRouteDuration(sLat, sLng, dLat, dLng);

        double angle = calculateBearing(LatLng(sLat, sLng), LatLng(dLat, dLng));

        setState(() {
          marker.add(Marker(
            markerId: const MarkerId("destinMarker"),
            position: LatLng(dLat, dLng),
            draggable: false,
            rotation: angle,
            zIndex: 2,
            flat: true,
            icon: destinationIcon!,
            anchor: const Offset(0.5, 0.5),
          ));
        });
      } else {
        if (kDebugMode) {
          print('No coordinates found for the address.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  String _travelDuration = "";
  // Fetch duration from Google Directions API
  _calculateRouteDuration(double sLatitude, double sLongitude, double dLatitude,
      double dLongitude) async {
    final apiKey = dotenv.get('apiKey'); // Replace with your API key
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${sLatitude},${sLongitude}&destination=${dLatitude},${dLongitude}&mode=driving&key=${apiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract travel duration from the response
      if (kDebugMode) {
        print("CALCULATED");
      }
      if (data['routes'].isNotEmpty) {
        final duration = data['routes'][0]['legs'][0]['duration']['text'];
        setState(() {
          _travelDuration = duration;
        });
      }
    } else {
      print('Error fetching directions: ${response.statusCode}');
    }
  }

  bool isStarted = false;
  bool isOnRouteStarted = false;
  double isStartedHeight = 175;
  //GO TO PICK UP CLIENT CURRENT DRIVER ADDRESS TO CLIENT ADDRESS
  getPickupWithAddress(String _currentAddress) async {
    _setLoadingMenu(true);
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    CameraPosition cameraPosition =
        CameraPosition(target: LatLng(sLat, sLng), zoom: 15.6);
    _controllers!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    getCoordinatesFromAddress(destLoc.toString());

    if (mounted) {
      setState(() {
        marker.add(Marker(
          markerId: const MarkerId("originMarker"),
          position: LatLng(position.latitude, position.longitude),
          rotation: position.headingAccuracy,
          draggable: false,
          zIndex: 2,
          flat: true,
          icon: driverIcon!,
          anchor: const Offset(0.5, 0.5),
        ));

        // SHWING CLIENT INFROMATION
        isStarted = true;
        isStartedHeight = 240;
      });
    }

    List<LatLng>? coordinates =
        await _googleMapPolyline.getPolylineCoordinatesWithAddress(
            origin: _currentAddress.toString(),
            destination: originLoc.toString(),
            mode: RouteMode.driving);

    if (mounted) {
      setState(() {
        _polylines.clear();
      });
    }

    _addPickupPolyline(coordinates);
    _setLoadingMenu(false);
  }

  _addPickupPolyline(List<LatLng>? coordinates) {
    PolylineId id = PolylineId("pickup_poly$_polylineCount");
    Polyline polyline = Polyline(
        polylineId: id,
        patterns: patterns[0],
        color: primaryColor,
        points: coordinates!,
        width: 5,
        onTap: () {});

    if (mounted) {
      setState(() {
        _polylines[id] = polyline;
        _polylineCount++;
      });
    }
  }

  _setLoadingMenu(bool status) {
    if (mounted) {
      setState(() {
        _loading = status;
      });
    }
  }

  String requestId = '';
  bool dataLoaded = false; // Add a flag to check if data is loaded

  String? originLoc, destLoc, clientPhone, clientNames;

  @override
  void initState() {
    super.initState();
    marker.addAll(_list);
    updateSentRequestStatusBloc =
        BlocProvider.of<UpdateSentRequestStatusBloc>(context);
    _getCurrentLocation();
    setClientDriverMarkerIcons();
    originLoc = widget.originLocation.toString();
    destLoc = widget.destinationLocation.toString();
    clientNames = widget.clientNames.toString();
    clientPhone = widget.clientPhone.toString();
    requestId = widget.requestId.toString();
  }

  void _updateRequestStatus(String newStatus, int requestId) {
    updateSentRequestStatusBloc.add(
        HandleUpdateStatus(requestId: requestId.toString(), status: newStatus));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        backgroundColor: whiteColor,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: primaryColor,
          title: const Text('MAP DIRECTIONS'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.safeGoNamed(home);
            },
          ),
        ),
        body: Container(
          color: whiteColor,
          child: LayoutBuilder(
            builder: (context, cont) {
              return Column(
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height:
                        MediaQuery.of(context).size.height - isStartedHeight,
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        controllerGoogleMapCompleter.complete(controller);
                        _controllers = controller;
                        _getCurrentLocation();
                        // getAvailableDriver();
                      },
                      markers: Set<Marker>.of(marker),
                      polylines: Set<Polyline>.of(_polylines.values),
                      initialCameraPosition: CameraPosition(
                        target: initialPosition,
                        zoom: 15,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isStarted,
                    child: Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 10),
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Duration",
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor),
                                ),
                                Text(
                                  _travelDuration.isEmpty
                                      ? "Calculating..."
                                      : " $_travelDuration",
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: orangeColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _loading
            ? Container(
                color: Colors.green.withOpacity(0.20),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SpinKitCircle(
                        color: primaryColor,
                        size: 60,
                      ),
                      Text(
                        'Loading Directions...',
                        style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              )
            : Container(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
