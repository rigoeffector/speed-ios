// client/advanced_client_tracking_screen.dart
// Advanced Client App - Real-time driver tracking with premium UI

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF10B981);
const _kAccent = Color(0xFF07B363);
const _kGreen = Color(0xFF00D4A3);
const _kOrange = Color(0xFFFF6B35);
const _kSurface = Color(0xFFF8F7FF);
const _kCard = Color(0xFFFFFFFF);

// ─── Status Config ────────────────────────────────────────────────────────────
class _StatusConfig {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _StatusConfig(this.emoji, this.title, this.subtitle, this.color);
}

const _statusConfigs = {
  'started': _StatusConfig('✅', 'Driver Accepted', 'Your driver is getting ready', _kAccent),
  'driver_arriving': _StatusConfig('🚗', 'Driver On the Way', 'Heading to your pickup', _kOrange),
  'arrived_at_pickup': _StatusConfig('📍', 'Driver Arrived', 'Your driver is waiting for you', _kGreen),
  'client_on_board': _StatusConfig('🎯', 'Trip in Progress', "You're on your way!", _kAccent),
  'completed': _StatusConfig('🏁', 'Arrived!', 'You have reached your destination', _kGreen),
  'cancelled': _StatusConfig('❌', 'Trip Cancelled', 'This trip has been cancelled', Colors.red),
  'cancelled_by_client': _StatusConfig('❌', 'Trip Cancelled', 'Trip was cancelled', Colors.red),
};

// ─── Main Screen ─────────────────────────────────────────────────────────────
class AdvancedClientTrackingScreen extends StatefulWidget {
  final String? requestId;
  final String? clientPhone;
  final String? clientNames;
  final String? destinationLocation;
  final String? originLocation;
  final String? driverName;
  final String? driverPhone;

  const AdvancedClientTrackingScreen({
    super.key,
     this.requestId,
    this.clientPhone,
    this.clientNames,
    this.destinationLocation,
    this.originLocation,
    this.driverName,
    this.driverPhone,
  });

  @override
  _AdvancedClientTrackingScreenState createState() =>
      _AdvancedClientTrackingScreenState();
}

class _AdvancedClientTrackingScreenState
    extends State<AdvancedClientTrackingScreen>
    with TickerProviderStateMixin {

  // ─── Controllers ────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bounceAnim;

  // ─── Firebase ───────────────────────────────────────────────────────────
  final _db = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _tripSub;
  StreamSubscription<DatabaseEvent>? _locationSub;
  StreamSubscription<DatabaseEvent>? _metricsSub;

  // ─── State ──────────────────────────────────────────────────────────────
  String _tripStatus = 'started';
  bool _driverConnected = false;
  bool _mapReady = false;
  bool _isLoading = true;
  bool _sheetExpanded = false;
  bool _routeDrawn = false;
  int _ratingStars = 5;

  // Location
  LatLng _clientPosition = const LatLng(-1.9706, 30.1044);
  LatLng _pickupPosition = const LatLng(0, 0);
  LatLng _dropoffPosition = const LatLng(0, 0);
  LatLng? _driverPosition;
  double _driverBearing = 0;
  double _driverSpeed = 0;

  // Trip details
  String _driverName = '';
  String _driverPhone = '';
  String _pickupAddress = '';
  String _dropoffAddress = '';

    // Fare details
  String _totalFarePrice = '';
  String _totalFareDistance = '';
  String _farePerKm = '';

  // Metrics
  String _distance = '---';
  String _duration = '---';
  String _eta = '---';
  double _progress = 0;

  // Map
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _clientIcon;
  BitmapDescriptor? _destIcon;

  // ─── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _bounceCtrl.dispose();
    _tripSub?.cancel();
    _locationSub?.cancel();
    _metricsSub?.cancel();
    _mapController?.dispose();
    _db.ref('active_trips/${widget.requestId}').update({'clientConnected': false});
    super.dispose();
  }

  // ─── Setup ──────────────────────────────────────────────────────────────
  void _setupAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _bounceAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _initialize() async {
    await _createCustomMarkers();
    await _getCurrentLocation();
    await _connectToFirebase();
    _slideCtrl.forward();
    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Custom Markers ─────────────────────────────────────────────────────
  Future<void> _createCustomMarkers() async {
    _driverIcon = await _buildMarkerIcon(
      bgColor: _kAccent,
      iconData: Icons.directions_car_rounded,
      size: 110,
    );
    _clientIcon = await _buildMarkerIcon(
      bgColor: _kGreen,
      iconData: Icons.person_pin_circle_rounded,
      size: 110,
    );
    _destIcon = await _buildMarkerIcon(
      bgColor: _kOrange,
      iconData: Icons.flag_rounded,
      size: 110,
    );
  }

  Future<BitmapDescriptor> _buildMarkerIcon({
    required Color bgColor,
    required IconData iconData,
    double size = 100,
  }) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final r = size / 2;

    // Outer glow
    final glowPaint = Paint()
      ..color = bgColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(r, r), r * 0.85, glowPaint);

    // Main circle
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(Offset(r, r), r * 0.7, bgPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(r, r), r * 0.7, borderPaint);

    // Icon
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size * 0.38,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
      ),
      )
      ..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ─── Location ───────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _clientPosition = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  // ─── Firebase ───────────────────────────────────────────────────────────
  Future<void> _connectToFirebase() async {
    final tripId = widget.requestId;
    final tripRef = _db.ref('active_trips/$tripId');

    // Mark client connected
    await tripRef.update({
      'clientConnected': true,
      'lastClientConnection': DateTime.now().toIso8601String(),
    });

    // Set disconnect handler
    await tripRef.onDisconnect().update({'clientConnected': false});

    // Load initial data
    final snap = await tripRef.get();
    if (snap.exists) {
      _parseAndApplyTripData(snap.value as Map);
    }

    // Listen to full trip
    _tripSub = tripRef.onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      _parseAndApplyTripData(event.snapshot.value as Map);
    });

    // Listen to driver location separately for lower latency
    _locationSub = tripRef.child('driver_location').onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      final d = Map<String, dynamic>.from(event.snapshot.value as Map);
      _handleDriverLocationUpdate(d);
    });
  }

  void _parseAndApplyTripData(Map data) {
    if (!mounted) return;

    final driver = data['driver'] as Map? ?? {};
    final pickup = data['pickup'] as Map? ?? {};
    final dropoff = data['dropoff'] as Map? ?? {};
    final metrics = data['metrics'] as Map? ?? {};
    final driverLoc = data['driver_location'] as Map? ?? {};
    final fare = data['fare'] as Map? ?? {};


    final newStatus = data['status'] as String? ?? 'started';
    final prevStatus = _tripStatus;

    setState(() {
      _tripStatus = newStatus;
      _driverConnected = data['driverConnected'] as bool? ?? false;
      _driverName = driver['name'] as String? ?? widget.driverName ?? 'Driver';
      _driverPhone = driver['phone']?.toString() ?? widget.driverPhone ?? '';


      _totalFarePrice = fare['totalFare']?.toString() ?? '';
      _totalFareDistance = fare['totalDistance']?.toString() ?? '';
      _farePerKm = fare['farePerKm']?.toString() ?? '';



      _pickupAddress = pickup['address'] as String? ?? widget.originLocation ?? '';
      _dropoffAddress = dropoff['address'] as String? ?? widget.destinationLocation ?? '';

      if ((pickup['latitude'] as num?) != null) {
        _pickupPosition = LatLng(
          (pickup['latitude'] as num).toDouble(),
          (pickup['longitude'] as num).toDouble(),
        );
      }
      if ((dropoff['latitude'] as num?) != null) {
        _dropoffPosition = LatLng(
          (dropoff['latitude'] as num).toDouble(),
          (dropoff['longitude'] as num).toDouble(),
        );
      }

      // Metrics
      final rem = (metrics['remainingDistance'] as num?)?.toDouble() ?? 0;
      final init = (metrics['initialDistance'] as num?)?.toDouble() ?? 1;
      final dur = (metrics['estimatedDuration'] as num?)?.toInt() ?? 0;
      _distance = _fmtDist(rem);
      _duration = _fmtDur(dur);
      _eta = metrics['estimatedArrival'] as String? ?? '---';
      _progress = ((init - rem) / init).clamp(0.0, 1.0);

      // Driver location
      if (driverLoc.isNotEmpty) {
        _driverPosition = LatLng(
          (driverLoc['latitude'] as num).toDouble(),
          (driverLoc['longitude'] as num).toDouble(),
        );
        _driverBearing = (driverLoc['bearing'] as num?)?.toDouble() ?? 0;
        _driverSpeed = (driverLoc['speed'] as num?)?.toDouble() ?? 0;
      }
    });

    // Status changed — show notification
    if (prevStatus != newStatus) _onStatusChanged(newStatus);

    _refreshMapMarkers();

    // Draw route once
    if (!_routeDrawn && _pickupPosition.latitude != 0 && _dropoffPosition.latitude != 0) {
      _routeDrawn = true;
      _drawRoute();
    }
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> d) {
    if (!mounted) return;
    final newPos = LatLng(
      (d['latitude'] as num).toDouble(),
      (d['longitude'] as num).toDouble(),
    );

    // Ignore micro-updates
    if (_driverPosition != null) {
      final dist = Geolocator.distanceBetween(
        _driverPosition!.latitude,
        _driverPosition!.longitude,
        newPos.latitude,
        newPos.longitude,
      );
      if (dist < 3) return;
    }

    setState(() {
      _driverPosition = newPos;
      _driverBearing = (d['bearing'] as num?)?.toDouble() ?? _driverBearing;
      _driverSpeed = (d['speed'] as num?)?.toDouble() ?? _driverSpeed;
    });

    _refreshMapMarkers();
  }

  void _onStatusChanged(String status) {
    HapticFeedback.mediumImpact();
    if (status == 'completed') {
      _showCompletionSheet();
    } else if (status == 'cancelled' || status == 'cancelled_by_client') {
      _showCancellationDialog();
    } else if (status == 'arrived_at_pickup') {
      _showDriverArrivedSnack();
    }
  }

  // ─── Map ────────────────────────────────────────────────────────────────
  void _refreshMapMarkers() {
    if (!mounted) return;
    final updatedMarkers = <Marker>{};
    final updatedCircles = <Circle>{};

    // Pickup marker
    if (_pickupPosition.latitude != 0 && _clientIcon != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPosition,
        icon: _clientIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: 'Your Pickup', snippet: _pickupAddress),
      ));
      updatedCircles.add(Circle(
        circleId: const CircleId('pickupCircle'),
        center: _pickupPosition,
        radius: 60,
        fillColor: _kGreen.withOpacity(0.12),
        strokeColor: _kGreen.withOpacity(0.4),
        strokeWidth: 2,
      ));
    }

    // Dropoff marker
    if (_dropoffPosition.latitude != 0 && _destIcon != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffPosition,
        icon: _destIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: 'Destination', snippet: _dropoffAddress),
      ));
      updatedCircles.add(Circle(
        circleId: const CircleId('dropoffCircle'),
        center: _dropoffPosition,
        radius: 60,
        fillColor: _kOrange.withOpacity(0.12),
        strokeColor: _kOrange.withOpacity(0.4),
        strokeWidth: 2,
      ));
    }

    // Driver marker
    if (_driverPosition != null && _driverIcon != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition!,
        icon: _driverIcon!,
        rotation: _driverBearing,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: _driverName,
          snippet: '${(_driverSpeed * 3.6).toStringAsFixed(0)} km/h',
      ),
      ));
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(updatedMarkers);
      _circles
        ..clear()
        ..addAll(updatedCircles);
    });
  }

  Future<void> _drawRoute() async {
    try {
      final apiKey = dotenv.get('apiKey');
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_pickupPosition.latitude},${_pickupPosition.longitude}'
        '&destination=${_dropoffPosition.latitude},${_dropoffPosition.longitude}'
        '&mode=driving&key=$apiKey',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if ((data['routes'] as List).isNotEmpty) {
          final pts = _decodePolyline(
            data['routes'][0]['overview_polyline']['points'] as String,
          );
          if (!mounted) return;
          setState(() {
            _polylines
              ..clear()
              ..add(Polyline(
                polylineId: const PolylineId('route'),
                points: pts,
                color: _kAccent,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                geodesic: true,
              ));
          });
          _fitBounds();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Route error: $e');
    }
  }

  void _fitBounds() {
    if (_mapController == null || _pickupPosition.latitude == 0) return;
    final lats = [_pickupPosition.latitude, _dropoffPosition.latitude];
    final lngs = [_pickupPosition.longitude, _dropoffPosition.longitude];
    if (_driverPosition != null) {
      lats.add(_driverPosition!.latitude);
      lngs.add(_driverPosition!.longitude);
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
          northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      ),
        80,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final pts = <LatLng>[];
    int i = 0;
    int lat = 0, lng = 0;
    while (i < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return pts;
  }

  // ─── Utilities ──────────────────────────────────────────────────────────
  String _fmtDist(double m) {
    if (m <= 0) return '---';
    return m < 1000 ? '${m.toStringAsFixed(0)} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _fmtDur(int s) {
    if (s <= 0) return '---';
    final h = s ~/ 3600, m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    if (m > 0) return '${m}min';
    return '<1min';
  }

  void _callDriver() {
    if (_driverPhone.isNotEmpty) {
      FlutterPhoneDirectCaller.callNumber('+$_driverPhone');
    }
  }

  // ─── Dialogs / Sheets ───────────────────────────────────────────────────
  void _showDriverArrivedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Driver has arrived!',
                  style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700, color: Colors.white),
            ),
                Text(
                  'Head to your pickup point',
                  style: GoogleFonts.sora(
                      fontSize: 12, color: Colors.white.withOpacity(0.85)),
            ),
            ],
        ),
        ],
      ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: '❌',
        iconColor: Colors.red,
        title: 'Trip Cancelled',
        message: 'This trip has been cancelled.',
        actions: [
          _DialogAction(
            label: 'Go Home',
            isPrimary: true,
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
        ),
        ],
      ),
    );
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(
        driverName: _driverName,
        totalPrice: _totalFarePrice,
        onRate: (stars, feedback) async {
          await _db.ref('active_trips/${widget.requestId}/rating').set({
            'stars': stars,
            'feedback': feedback,
            'ratedAt': DateTime.now().toIso8601String(),
          });
          if (mounted) context.go('/');
        },
        onSkip: () => context.go('/'),
        onConfirmPayment: () => context.go('/'),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final config = _statusConfigs[_tripStatus] ??
        const _StatusConfig('🚗', 'Tracking', 'Your trip is active', _kAccent);

    return Scaffold(
      backgroundColor: _kPrimary,
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          Positioned.fill(
            bottom: 280,
            child: GoogleMap(
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                setState(() => _mapReady = true);
                Future.delayed(const Duration(milliseconds: 800), _fitBounds);
              },
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
              initialCameraPosition: CameraPosition(
                target: _clientPosition,
                zoom: 15,
          ),
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
        ),
        ),

          // ── Gradient overlay at bottom of map ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 260,
            height: 80,
            child: DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _kSurface.withOpacity(0.9),
                ],
            ),
          ),
        ),
        ),

          // ── App Bar ──────────────────────────────────────────────────────
          _buildAppBar(config),

          // ── Live badge ──────────────────────────────────────────────────
          Positioned(
            top: 110,
            right: 16,
            child: _buildLiveBadge(),
        ),

          // ── Recenter FAB ────────────────────────────────────────────────
          Positioned(
            bottom: 300,
            right: 16,
            child: _buildFab(Icons.my_location_rounded, _fitBounds),
        ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildBottomPanel(config),
            ),
          ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar(_StatusConfig config) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kPrimary.withOpacity(0.95),
                  _kAccent.withOpacity(0.85),
              ],
          ),
            boxShadow: [
              BoxShadow(
                  color: _kAccent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
            ),
            ],
        ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        width: 40,
                        height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                    ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
                    const SizedBox(width: 14),

                    // Status info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                config.emoji,
                                style: const TextStyle(fontSize: 18),
                          ),
                              const SizedBox(width: 6),
                              Text(
                                config.title,
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                            ),
                          ),
                          ],
                      ),
                          const SizedBox(height: 2),
                          Text(
                            config.subtitle,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      ],
                  ),
                ),

                    // Driver connection dot
                    Container(
                      width: 10,
                      height: 10,
                    decoration: BoxDecoration(
                        color: _driverConnected ? _kGreen : Colors.orange,
                        shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: (_driverConnected ? _kGreen : Colors.orange)
                                .withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                      ),
                      ],
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

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kGreen.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 2),
          ),
          ],
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
              decoration: BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                        color: _kGreen.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 2)
                ],
            ),
          ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  letterSpacing: 1.2,
            ),
          ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFab(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4))
        ],
      ),
        child: Icon(icon, color: _kPrimary, size: 22),
      ),
    );
  }

  Widget _buildBottomPanel(_StatusConfig config) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
          ),
        ),
        ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                // ── Status steps ─────────────────────────────────────────
                _buildStatusStepper(),
                const SizedBox(height: 16),

                // ── Metrics row ──────────────────────────────────────────
                _buildMetricsRow(),
                const SizedBox(height: 16),

                // ── Progress bar ─────────────────────────────────────────
                _buildProgressBar(),
                const SizedBox(height: 20),

                // ── Driver card ──────────────────────────────────────────
                _buildDriverCard(),
            ],
        ),
        ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    final stepLabels = ['Accepted', 'On Way', 'Arrived', 'On Board', 'Done'];
    final stepIcons = [
      Icons.check_circle_outline_rounded,
      Icons.directions_car_rounded,
      Icons.location_on_rounded,
      Icons.airline_seat_recline_normal_rounded,
      Icons.flag_rounded,
    ];

    final statusKeys = [
      'started', 'driver_arriving', 'arrived_at_pickup', 'client_on_board', 'completed'
    ];
    final currentStep = statusKeys.indexOf(_tripStatus);

    return Row(
      children: List.generate(stepLabels.length, (i) {
        final done = i <= currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: active ? 36 : 28,
                      height: active ? 36 : 28,
                    decoration: BoxDecoration(
                        color: done ? _kAccent : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 8)]
                            : null,
                  ),
                      child: Icon(
                        stepIcons[i],
                        size: active ? 18 : 14,
                        color: done ? Colors.white : Colors.grey.shade400,
                  ),
                ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabels[i],
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: done ? _kPrimary : Colors.grey.shade400,
                  ),
                      textAlign: TextAlign.center,
                ),
                ],
            ),
          ),
              if (i < stepLabels.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 2,
                    color: i < currentStep ? _kAccent : Colors.grey.shade200,
              ),
            ),
          ],
        ),
        );
      }),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _MetricCard(
          icon: Icons.straighten_rounded,
          label: 'Distance',
          value: _distance,
          color: _kAccent,
      ),
        const SizedBox(width: 10),
        _MetricCard(
          icon: Icons.timer_outlined,
          label: 'ETA',
          value: _duration,
          color: _kOrange,
      ),
        const SizedBox(width: 10),
        _MetricCard(
          icon: Icons.schedule_rounded,
          label: 'Arrives',
          value: _eta,
          color: _kGreen,
      ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trip Progress',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
          ),
        ),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: _kAccent,
                fontWeight: FontWeight.w700,
          ),
        ),
        ],
      ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
            minHeight: 7,
        ),
      ),
      ],
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent.withOpacity(0.85)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
      ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
        ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
        ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR DRIVER',
                  style: GoogleFonts.sora(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.5,
              ),
            ),
                Text(
                  _driverName.isNotEmpty ? _driverName : 'Driver',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
              ),
            ),
                Row(
                  children: [
                    Icon(Icons.speed_rounded,
                        size: 12, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '${(_driverSpeed * 3.6).toStringAsFixed(0)} km/h',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                  ),
                ),
                ],
            ),
            ],
        ),
        ),

          // Call button
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: GestureDetector(
                onTap: _callDriver,
                child: Container(
                  width: 46,
                  height: 46,
                decoration: BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                          color: _kGreen.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2),
                  ],
              ),
                  child: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
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
      child: Container(
        color: _kPrimary.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -_bounceAnim.value),
                  child: Container(
                    width: 72,
                    height: 72,
                  decoration: BoxDecoration(
                      color: _kAccent,
                      shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                            color: _kAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 4),
                    ],
                ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 36),
              ),
            ),
          ),
              const SizedBox(height: 24),
              Text(
                'Connecting to driver...',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
            ),
          ),
              const SizedBox(height: 8),
              Text(
                'Setting up live tracking',
                style: GoogleFonts.sora(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
            ),
          ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Reusable Metric Card ─────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
      ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
          ),
        ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
          ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
        ),
        ],
      ),
      ),
    );
  }
}

// ─── Rating Bottom Sheet ──────────────────────────────────────────────────────
class _RatingSheet extends StatefulWidget {
  final String driverName;
  final String totalPrice;
  final void Function(int stars, String? feedback) onRate;
  final VoidCallback onSkip;
  final VoidCallback onConfirmPayment;

  const _RatingSheet({
    required this.driverName,
    required this.totalPrice,
    required this.onRate,
    required this.onSkip,
    required this.onConfirmPayment,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _ctrl = TextEditingController();

  final List<String> _quickTags = [
    '👍 Great Driver',
    '🚗 Smooth Ride',
    '⏱ On Time',
    '😊 Friendly',
    '🧹 Clean Car',
  ];

  final Set<String> _selectedTags = {};

  String get _ratingLabel {
    switch (_stars) {
      case 1: return 'Very Bad 😞';
      case 2: return 'Bad 😕';
      case 3: return 'Okay 😐';
      case 4: return 'Good 😊';
      case 5: return 'Excellent! 🤩';
      default: return 'Tap a star to rate';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Trip summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary.withOpacity(0.08), _kAccent.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
               
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Completed!',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'with ${widget.driverName}',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Fare',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${widget.totalPrice} RWF',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'How was your ride?',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),

          // Dynamic rating label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _ratingLabel,
              key: ValueKey(_stars),
              style: GoogleFonts.sora(
                fontSize: 13,
                color: _stars > 0 ? _kAccent : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: filled ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? Colors.amber : Colors.grey.shade300,
                      size: 44,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Quick tag chips
          if (_stars > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What went well?',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kAccent.withOpacity(0.12) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selected ? _kAccent : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kAccent : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Comment field
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)',
              hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _kAccent, width: 1.5),
              ),
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: Colors.grey.shade400),
            ),
            maxLines: 3,
            style: GoogleFonts.sora(fontSize: 13),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.sora(color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _stars == 0
                      ? null
                      : () {
                          final tagFeedback = _selectedTags.isNotEmpty
                              ? _selectedTags.join(', ')
                              : null;
                          final comment = _ctrl.text.trim().isEmpty
                              ? tagFeedback
                              : '${_ctrl.text.trim()}${tagFeedback != null ? ' | $tagFeedback' : ''}';
                          widget.onRate(_stars, comment);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Rating',
                    style: GoogleFonts.sora(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Styled Dialog ────────────────────────────────────────────────────────────
class _StyledDialog extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<_DialogAction> actions;

  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            Text(message,
                style: GoogleFonts.sora(
                    fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: a.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: a.isPrimary ? _kAccent : Colors.grey.shade100,
                        foregroundColor: a.isPrimary ? Colors.white : _kPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                  ),
                      child: Text(a.label,
                          style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
                ),
              ),
                )),
        ],
      ),
      ),
    );
  }
}

class _DialogAction {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _DialogAction({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
}