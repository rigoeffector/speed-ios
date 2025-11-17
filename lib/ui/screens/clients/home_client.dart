// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
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

class _ClientDirectionsState extends State<ClientDirections>
    with TickerProviderStateMixin {
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
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

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

    // Main animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Pulse animation for active elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer effect for loading
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

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

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    locatePosition(position);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
  }

  bool loading = false;
  LatLng initialPosition = const LatLng(0, 0);
  LatLng destinationPosition = const LatLng(0, 0);
  String locationSelected = "";
  double dLat = 0.0, dLng = 0.0;
  double sLat = 0.0, sLng = 0.0;
  String? countryCode = "rw";

  int _polylineCount = 1;
  int _polylineRouteCount = 1;
  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  final GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: dotenv.get('apiKey'));

  List<List<PatternItem>> patterns = <List<PatternItem>>[
    <PatternItem>[],
    <PatternItem>[PatternItem.dash(30.0), PatternItem.gap(20.0)],
    <PatternItem>[PatternItem.dot, PatternItem.gap(10.0)],
    <PatternItem>[
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
    return (bearing + 360) % 360;
  }

  Future<void> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

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
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  String _travelDuration = "";
  String _travelDistance = "";

  _calculateRouteDuration(double sLatitude, double sLongitude, double dLatitude,
      double dLongitude) async {
    final apiKey = dotenv.get('apiKey');
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$sLatitude,$sLongitude&destination=$dLatitude,$dLongitude&mode=driving&key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final duration = data['routes'][0]['legs'][0]['duration']['text'];
        final distance = data['routes'][0]['legs'][0]['distance']['text'];
        setState(() {
          _travelDuration = duration;
          _travelDistance = distance;
        });
      }
    } else {
      print('Error fetching directions: ${response.statusCode}');
    }
  }

  bool isStarted = false;

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

        isStarted = true;
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
  bool dataLoaded = false;
  String? originLoc, destLoc, clientPhone, clientNames;

  void _updateRequestStatus(String newStatus, int requestId) {
    updateSentRequestStatusBloc.add(
        HandleUpdateStatus(requestId: requestId.toString(), status: newStatus));
  }

  void _recenterMap() async {
    if (_controllers != null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15.6,
        bearing: 0,
        tilt: 0,
      );
      _controllers!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _buildGlassAppBar(),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              controllerGoogleMapCompleter.complete(controller);
              _controllers = controller;
              _getCurrentLocation();
            },
            markers: Set<Marker>.of(marker),
            polylines: Set<Polyline>.of(_polylines.values),
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            // styles: _mapStyle,
          ),

          // Elegant gradient overlays
          _buildTopGradientOverlay(),
          _buildBottomGradientOverlay(),

          // Floating recenter button
          Positioned(
            top: 100,
            right: 16,
            child: _buildFloatingActionButton(
              icon: Icons.my_location_rounded,
              onPressed: _recenterMap,
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
            ),
          ),

          // Bottom Info Card
          if (isStarted) _buildBottomInfoCard(),

          // Loading Overlay
          if (_loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // Glassmorphic App Bar
  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.85),
                primaryColor.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.safeGoNamed(home),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Live Tracking',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Gradient gradient,
  }) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGradientOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle with gradient
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[400]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      children: [
                        // Trip Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildElegantStatCard(
                                icon: Icons.access_time_rounded,
                                label: 'Duration',
                                value: _travelDuration.isEmpty
                                    ? "..."
                                    : _travelDuration,
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.12),
                                    primaryColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildElegantStatCard(
                                icon: Icons.route_rounded,
                                label: 'Distance',
                                value: _travelDistance.isEmpty
                                    ? "..."
                                    : _travelDistance,
                                gradient: LinearGradient(
                                  colors: [
                                    orangeColor.withOpacity(0.12),
                                    orangeColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: orangeColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Elegant Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey[300]!,
                                Colors.grey[300]!,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Client Info Section
                        _buildClientInfoSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.2),
                  accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentColor,
              height: 1.0,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),

          // Client details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientNames ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A202C),
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      clientPhone ?? 'No phone',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call button with animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (clientPhone != null) {
                    FlutterPhoneDirectCaller.callNumber(clientPhone!);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [greenColor, Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: greenColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                        // Spinner
                        const SpinKitRing(
                          color: primaryColor,
                          size: 65,
                          lineWidth: 5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Loading Route',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A202C),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Preparing your journey',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom map style (optional - for a more elegant map appearance)
  String get _mapStyle => '''
  [
    {
      "featureType": "poi",
      "elementType": "labels.text",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.business",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';
}
