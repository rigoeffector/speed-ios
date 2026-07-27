// client/advanced_client_tracking_screen.dart
// Advanced Client App - Real-time driver tracking with premium UI
// FIXES: marker painter (teardrop stem), route draw from client→pickup→dropoff,
//        dark map style contrast, improved bottom sheet, animated driver icon

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/received.sent.requests.model.dart';
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
const _kPrimary  = Color(0xFF10B981);   // emerald-500
const _kAccent   = Color(0xFF059669);   // emerald-600
const _kGreen    = Color(0xFF34D399);   // emerald-400 — pickup/positive
const _kRed      = Color(0xFFE63946);   // destination — vivid red
const _kAmber    = Color(0xFFF4A261);   // driver icon
const _kSurface  = Color(0xFFF0FDF4);   // emerald-50 tint
const _kCard     = Color(0xFFFFFFFF);

enum _RouteStopType { origin, checkpoint, destination }

class _RouteStopData {
  final String id;
  final String title;
  final LatLng position;
  final _RouteStopType type;
  final int order;
  final bool isCompleted;
  final String? subtitle;

  const _RouteStopData({
    required this.id,
    required this.title,
    required this.position,
    required this.type,
    required this.order,
    this.isCompleted = false,
    this.subtitle,
  });
}

// ─── Status Config ────────────────────────────────────────────────────────────
class _StatusConfig {
  final String emoji, title, subtitle;
  final Color color;
  const _StatusConfig(this.emoji, this.title, this.subtitle, this.color);
}

class _FlowStepData {
  final String label;
  final IconData icon;

  const _FlowStepData({required this.label, required this.icon});
}

const _rideStatusConfigs = <String, _StatusConfig>{
  'started':           _StatusConfig('✅', 'Driver Accepted',    'Your driver is getting ready',         _kAccent),
  'driver_arriving':   _StatusConfig('🚗', 'Driver On the Way',  'Heading to your pickup',               _kAmber),
  'arrived_at_pickup': _StatusConfig('📍', 'Driver Arrived',     'Your driver is waiting for you',       _kGreen),
  'client_on_board':   _StatusConfig('🎯', 'Trip in Progress',   "You're on your way!",                  _kAccent),
  'completed':         _StatusConfig('🏁', 'Arrived!',           'You have reached your destination',    _kGreen),
  'cancelled':         _StatusConfig('❌', 'Trip Cancelled',     'This trip has been cancelled',         Colors.red),
  'cancelled_by_client': _StatusConfig('❌', 'Trip Cancelled',   'Trip was cancelled',                  Colors.red),
};

const _rideFlowSteps = <_FlowStepData>[
  _FlowStepData(label: 'Accepted', icon: Icons.check_circle_outline_rounded),
  _FlowStepData(label: 'On Way', icon: Icons.directions_car_rounded),
  _FlowStepData(label: 'Arrived', icon: Icons.location_on_rounded),
  _FlowStepData(label: 'On Board', icon: Icons.airline_seat_recline_normal_rounded),
  _FlowStepData(label: 'Done', icon: Icons.flag_rounded),
];

const _courierFlowSteps = <_FlowStepData>[
  _FlowStepData(label: 'Approved', icon: Icons.verified_rounded),
  _FlowStepData(label: 'Collect', icon: Icons.inventory_2_rounded),
  _FlowStepData(label: 'Transit', icon: Icons.two_wheeler_rounded),
  _FlowStepData(label: 'Drops', icon: Icons.local_shipping_rounded),
  _FlowStepData(label: 'Done', icon: Icons.task_alt_rounded),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────
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
    extends State<AdvancedClientTrackingScreen> with TickerProviderStateMixin {

  // ─── Controllers ────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _driverPulseCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _driverPulseAnim;

  // ─── Firebase ───────────────────────────────────────────────────────────
  final _authService = AuthService();
  final _db = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _tripSub;
  StreamSubscription<DatabaseEvent>? _locationSub;

  // ─── State ──────────────────────────────────────────────────────────────
  String  _tripStatus      = 'started';
  bool    _driverConnected = false;
  bool    _mapReady        = false;
  bool    _isLoading       = true;
  bool    _routeDrawn      = false;
  bool    _isBottomSheetExpanded = true;
  String  _requestType     = 'RIDE';

  // Location
  LatLng  _clientPosition  = const LatLng(-1.9706, 30.1044);
  LatLng  _pickupPosition  = const LatLng(0, 0);
  LatLng  _dropoffPosition = const LatLng(0, 0);
  LatLng? _driverPosition;
  double  _driverBearing   = 0;
  double  _driverSpeed     = 0;

  // Trip details
  String _driverName     = '';
  String _driverPhone    = '';
  String _pickupAddress  = '';
  String _dropoffAddress = '';
  String _totalFarePrice = '';
  RequestContent? _requestDetails;
  List<_RouteStopData> _routeStops = const [];

  // Metrics
  String _distance = '---';
  String _duration = '---';
  String _eta      = '---';
  double _progress = 0;

  // Map
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle>   _circles   = {};

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _clientIcon;
  BitmapDescriptor? _destIcon;

  bool get _isCourier => _requestType.toUpperCase() == 'COURIER';
  double get _bottomSheetMapPadding => _isBottomSheetExpanded ? 300 : 168;
  double get _bottomSheetGradientBottom => _isBottomSheetExpanded ? 270 : 138;
  double get _bottomSheetFabBottom => _isBottomSheetExpanded ? 310 : 178;
  int get _activeRouteIndex => _resolveActiveRouteIndex();
  _RouteStopData? get _nextStop {
    if (_routeStops.isEmpty) return null;
    final index = _activeRouteIndex.clamp(0, _routeStops.length - 1);
    return _routeStops[index];
  }

  int get _completedCourierStops => _requestDetails?.courierCheckpoints
          .where((checkpoint) => checkpoint.checkpointStatus?.toUpperCase() == 'COMPLETED')
          .length ??
      0;

  int get _totalCourierStops => _requestDetails?.courierCheckpoints.length ?? 0;

  bool get _courierDriverApproved => _requestDetails?.courierFrom?.driverApproved == true;

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
    _driverPulseCtrl.dispose();
    _tripSub?.cancel();
    _locationSub?.cancel();
    _mapController?.dispose();
    if (widget.requestId?.isNotEmpty == true) {
      _db.ref('active_trips/${widget.requestId}').update({'clientConnected': false});
    }
    super.dispose();
  }

  // ─── Animations ─────────────────────────────────────────────────────────
  void _setupAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    _driverPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _bounceAnim = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _driverPulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _driverPulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _initialize() async {
    await _createCustomMarkers();
    await _getCurrentLocation();
    await _loadRequestDetails();
    await _connectToFirebase();
    _slideCtrl.forward();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRequestDetails() async {
    final requestId = widget.requestId;
    if (requestId == null || requestId.isEmpty) return;

    try {
      final request = await _authService.getRequestById(requestId);
      if (!mounted || request == null) return;
      _applyRequestDetails(request);
    } catch (e) {
      if (kDebugMode) {
        print('[Request] Failed to load request details: $e');
      }
    }
  }

  void _applyRequestDetails(RequestContent request) {
    final isFirstRequestLoad = _requestDetails == null;
    final routeStops = _buildRouteStops(request);
    final normalizedStatus = _normalizeStatus(request.status);

    setState(() {
      _requestDetails = request;
      if (isFirstRequestLoad && request.isCourier) {
        _isBottomSheetExpanded = false;
      }
      _requestType = (request.requestType ?? 'RIDE').toUpperCase();
      _tripStatus = normalizedStatus;
      _driverName = request.driverName?.trim().isNotEmpty == true
          ? request.driverName!.trim()
          : _driverName;
      _driverPhone = request.driverPhone?.trim().isNotEmpty == true
          ? request.driverPhone!.trim()
          : _driverPhone;

      if (request.actualFare != null && _totalFarePrice.isEmpty) {
        _totalFarePrice = request.actualFare!.toStringAsFixed(0);
      }

      final primaryPickup = request.isCourier
          ? request.courierFrom?.name
          : request.originLocation?.name;
      final primaryDropoff = request.isCourier
          ? request.courierTo?.name
          : request.destinationLocation;

      if (_pickupAddress.isEmpty) {
        _pickupAddress = primaryPickup ?? widget.originLocation ?? '';
      }
      if (_dropoffAddress.isEmpty) {
        _dropoffAddress = primaryDropoff ?? widget.destinationLocation ?? '';
      }

      _routeStops = routeStops;
    });

    _syncAnchorsFromStops();
    _refreshMapMarkers();
    _routeDrawn = false;
    _drawFullRoute();
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  List<Map<String, dynamic>> _asStringKeyedMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .map(_asStringKeyedMap)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _asText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  String _resolveDriverName(Map<String, dynamic> driver) {
    final directName = _asText(driver['name']);
    if (directName != null) return directName;

    final firstName = _asText(driver['firstName']);
    final lastName = _asText(driver['lastName']);
    final combined = [firstName, lastName].whereType<String>().join(' ').trim();
    if (combined.isNotEmpty) return combined;

    return widget.driverName?.trim().isNotEmpty == true
        ? widget.driverName!.trim()
        : 'Driver';
  }

  String _resolveDriverPhone(Map<String, dynamic> driver) {
    return _asText(driver['phone']) ??
        _asText(driver['telephone']) ??
        widget.driverPhone ??
        '';
  }

  double _fallbackProgress(
    String status, {
    required bool isCourier,
    required int completedStops,
    required int totalStops,
  }) {
    if (isCourier && totalStops > 0) {
      final ratio = (completedStops / totalStops).clamp(0.0, 1.0);
      if (status == 'completed') return 1.0;
      if (status == 'client_on_board') return math.max(ratio, 0.65);
      if (status == 'arrived_at_pickup') return math.max(ratio, 0.35);
      if (status == 'driver_arriving') return math.max(ratio, 0.2);
      return math.max(ratio, 0.08);
    }

    switch (status) {
      case 'completed':
        return 1.0;
      case 'client_on_board':
        return 0.72;
      case 'arrived_at_pickup':
        return 0.42;
      case 'driver_arriving':
        return 0.2;
      default:
        return 0.08;
    }
  }

  List<_RouteStopData> _buildRouteStopsFromRealtime(
    Map<String, dynamic> realtimeData,
    String normalizedStatus,
    String requestType,
  ) {
    final requestBody = _asStringKeyedMap(realtimeData['requestBody']) ?? const <String, dynamic>{};
    final pickup = _asStringKeyedMap(realtimeData['pickup']) ?? const <String, dynamic>{};
    final dropoff = _asStringKeyedMap(realtimeData['dropoff']) ?? const <String, dynamic>{};
    final checkpoints = _asStringKeyedMapList(
      realtimeData['checkpoints'] ?? requestBody['checkpoints'],
    )
      ..sort((a, b) => (_asInt(a['order']) ?? 0).compareTo(_asInt(b['order']) ?? 0));

    final rawStops = <_RouteStopData>[];
    final isCourier = requestType == 'COURIER';

    final origin = _asStringKeyedMap(
          isCourier ? requestBody['courierFrom'] : requestBody['originLocation'],
        ) ??
        pickup;
    final originLat = _asDouble(origin['latitude']);
    final originLng = _asDouble(origin['longitude']);
    if (_hasCoordinates(originLat, originLng)) {
      rawStops.add(_RouteStopData(
        id: 'origin',
        title: _asText(origin['name']) ?? _asText(pickup['address']) ?? 'Pickup',
        position: LatLng(originLat!, originLng!),
        type: _RouteStopType.origin,
        order: 0,
        isCompleted: isCourier || normalizedStatus == 'client_on_board' || normalizedStatus == 'completed',
        subtitle: _asText(origin['receiverName']),
      ));
    }

    final dropoffLat = _asDouble(dropoff['latitude']);
    final dropoffLng = _asDouble(dropoff['longitude']);
    final dropoffTitle = _asText(dropoff['address']) ??
        _asText(requestBody['destinationLocation']) ??
        _asText(realtimeData['destinationLocation']) ??
        'Destination';

    for (var i = 0; i < checkpoints.length; i++) {
      final checkpoint = checkpoints[i];
      final checkpointLat = _asDouble(checkpoint['latitude']);
      final checkpointLng = _asDouble(checkpoint['longitude']);
      if (!_hasCoordinates(checkpointLat, checkpointLng)) continue;

      final isCompleted = _asText(checkpoint['checkpointStatus'])?.toUpperCase() == 'COMPLETED';
      final isLastRideStop = !isCourier && i == checkpoints.length - 1;
      final stopType = isCourier
          ? _RouteStopType.checkpoint
          : (isLastRideStop ? _RouteStopType.destination : _RouteStopType.checkpoint);

      rawStops.add(_RouteStopData(
        id: 'checkpoint_${_asInt(checkpoint['order']) ?? i + 1}',
        title: _asText(checkpoint['name']) ??
            (stopType == _RouteStopType.destination ? dropoffTitle : 'Checkpoint'),
        position: LatLng(checkpointLat!, checkpointLng!),
        type: stopType,
        order: _asInt(checkpoint['order']) ?? i + 1,
        isCompleted: isCompleted || normalizedStatus == 'completed',
        subtitle: _asText(checkpoint['receiverName']) ?? _asText(checkpoint['checkpointStatus']),
      ));
    }

    if (isCourier && _hasCoordinates(dropoffLat, dropoffLng)) {
      rawStops.add(_RouteStopData(
        id: 'destination',
        title: dropoffTitle,
        position: LatLng(dropoffLat!, dropoffLng!),
        type: _RouteStopType.destination,
        order: rawStops.isEmpty ? 1 : rawStops.last.order + 1,
        isCompleted: normalizedStatus == 'completed',
        subtitle: _asText((_asStringKeyedMap(requestBody['courierTo']) ?? const {})['receiverName']),
      ));
    }

    if (!isCourier &&
        _hasCoordinates(dropoffLat, dropoffLng) &&
        (rawStops.isEmpty ||
            rawStops.last.type != _RouteStopType.destination ||
            !_sameCoordinate(rawStops.last.position, LatLng(dropoffLat!, dropoffLng!)))) {
      rawStops.add(_RouteStopData(
        id: 'destination',
        title: dropoffTitle,
        position: LatLng(dropoffLat!, dropoffLng!),
        type: _RouteStopType.destination,
        order: rawStops.isEmpty ? 1 : rawStops.last.order + 1,
        isCompleted: normalizedStatus == 'completed',
      ));
    }

    return _dedupeStops(rawStops);
  }

  // ─── Custom Marker Painter ───────────────────────────────────────────────
  // FIX: added teardrop stem so icon clearly points to exact coordinate
  Future<BitmapDescriptor> _buildMarkerIcon(
    Color color,
    IconData icon,
    double size, {
    String? label,
  }) async {
    final double r          = size / 2;
    final double stemH      = 22.0;
    final double labelH     = (label != null && label.isNotEmpty) ? 22.0 : 0.0;
    final double totalH     = size + stemH + labelH;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, Rect.fromLTWH(0, 0, size, totalH));

    // 1. Drop shadow
    canvas.drawCircle(
      Offset(r, r + 5),
      r * 0.70,
      Paint()
        ..color      = Colors.black.withOpacity(0.30)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );

    // 2. Outer glow ring
    canvas.drawCircle(
      Offset(r, r),
      r * 0.80,
      Paint()
        ..color      = color.withOpacity(0.28)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    // 3. White border
    canvas.drawCircle(Offset(r, r), r * 0.74, Paint()..color = Colors.white);

    // 4. Colored fill
    canvas.drawCircle(Offset(r, r), r * 0.65, Paint()..color = color);

    // 5. Gloss highlight
    canvas.drawCircle(
      Offset(r - r * 0.18, r - r * 0.18),
      r * 0.24,
      Paint()
        ..color      = Colors.white.withOpacity(0.28)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );

    // 6. Icon
    final iconPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign:     TextAlign.center,
    )
      ..text = TextSpan(
        text:  String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize:   size * 0.36,
          fontFamily: icon.fontFamily,
          package:    icon.fontPackage,
          color:      Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
      )
      ..layout();
    iconPainter.paint(
      canvas,
      Offset((size - iconPainter.width) / 2, (size - iconPainter.height) / 2),
    );

    // 7. Teardrop stem — points to exact LatLng on map
    final stemPath = Path()
      ..moveTo(r - 7, size - 5)
      ..quadraticBezierTo(r, size + stemH, r, size + stemH)
      ..quadraticBezierTo(r + 7, size - 5, r + 7, size - 5)
      ..close();

    canvas.drawPath(
      stemPath,
      Paint()
        ..color      = Colors.black.withOpacity(0.18)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawPath(stemPath, Paint()..color = color);
    canvas.drawPath(
      stemPath,
      Paint()
        ..color       = Colors.white
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 8. Optional label pill
    if (label != null && label.isNotEmpty) {
      final lp = TextPainter(
        textDirection: ui.TextDirection.ltr,
        textAlign:     TextAlign.center,
      )
        ..text = TextSpan(
          text:  label,
          style: TextStyle(
            fontSize:   size * 0.17,
            fontWeight: FontWeight.w700,
            color:      color,
          ),
        )
        ..layout(maxWidth: size);

      final pillTop  = size + stemH + 2;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(r, pillTop + 9),
          width:  lp.width + 16,
          height: 18,
        ),
        const Radius.circular(9),
      );
      canvas.drawRRect(pillRect, Paint()..color = Colors.white);
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color       = color.withOpacity(0.40)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      lp.paint(canvas, Offset((size - lp.width) / 2, pillTop + 1));
    }

    final picture = recorder.endRecording();
    final image   = await picture.toImage(size.toInt(), totalH.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _createCustomMarkers() async {
    _driverIcon = await _buildMarkerIcon(
        _kAmber, Icons.directions_car_filled_rounded, 120,
        label: 'Driver');
    _clientIcon = await _buildMarkerIcon(
        _kGreen, Icons.person_pin_circle_rounded, 110,
        label: 'Pickup');
    _destIcon = await _buildMarkerIcon(
        _kRed, Icons.flag_rounded, 110,
        label: 'Drop-off');
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
    final tripId  = widget.requestId;
    if (tripId == null || tripId.isEmpty) return;
    final tripRef = _db.ref('active_trips/$tripId');

    await tripRef.update({
      'clientConnected':       true,
      'lastClientConnection':  DateTime.now().toIso8601String(),
    });
    await tripRef.onDisconnect().update({'clientConnected': false});

    final snap = await tripRef.get();
    final initialTripData = _asStringKeyedMap(snap.value);
    if (snap.exists && initialTripData != null) {
      _parseAndApplyTripData(initialTripData);
    }

    _tripSub = tripRef.onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      final tripData = _asStringKeyedMap(event.snapshot.value);
      if (tripData != null) {
        _parseAndApplyTripData(tripData);
      }
    });

    // Separate high-frequency listener for driver position
    _locationSub = tripRef.child('driver_location').onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      final location = _asStringKeyedMap(event.snapshot.value);
      if (location != null) {
        _handleDriverLocationUpdate(location);
      }
    });
  }

  void _parseAndApplyTripData(Map<String, dynamic> data) {
    if (!mounted) return;

    final requestBody = _asStringKeyedMap(data['requestBody']) ?? const <String, dynamic>{};
    final driver = _asStringKeyedMap(data['driver']) ??
        _asStringKeyedMap(data['motorBiker']) ??
        _asStringKeyedMap(requestBody['motorBiker']) ??
        const <String, dynamic>{};
    final pickup = _asStringKeyedMap(data['pickup']) ?? const <String, dynamic>{};
    final dropoff = _asStringKeyedMap(data['dropoff']) ?? const <String, dynamic>{};
    final metrics = _asStringKeyedMap(data['metrics']) ?? const <String, dynamic>{};
    final driverLoc = _asStringKeyedMap(data['driver_location']) ?? const <String, dynamic>{};
    final fare = _asStringKeyedMap(data['fare']) ?? const <String, dynamic>{};

    final requestType = (_asText(data['requestType']) ??
            _asText(requestBody['requestType']) ??
            _requestDetails?.requestType ??
            _requestType)
        .toUpperCase();
    final newStatus = _normalizeStatus(_asText(data['status']) ?? _asText(requestBody['status']));
    final prevStatus = _tripStatus;
    final pickupAddress = _asText(pickup['address']) ?? _asText((_asStringKeyedMap(requestBody['originLocation']) ?? const {})['name']);
    final dropoffAddress = _asText(dropoff['address']) ??
        _asText(data['destinationLocation']) ??
        _asText(requestBody['destinationLocation']) ??
        _asText((_asStringKeyedMap(requestBody['courierTo']) ?? const {})['name']);
    final realtimeRouteStops = _buildRouteStopsFromRealtime(data, newStatus, requestType);
    final remainingDistance = _asDouble(metrics['remainingDistance']) ??
        _asDouble(metrics['distanceKm']) ??
        _asDouble(fare['totalDistance']) ??
        _requestDetails?.distanceKm;
    final initialDistance = _asDouble(metrics['initialDistance']) ?? remainingDistance ?? 1;
    final estimatedDuration = _asInt(metrics['estimatedDuration']) ?? _asInt(metrics['durationSeconds']) ?? 0;
    final totalCourierStops = realtimeRouteStops.where((stop) => stop.type != _RouteStopType.origin).length;
    final completedCourierStops = realtimeRouteStops
        .where((stop) => stop.type != _RouteStopType.origin && stop.isCompleted)
        .length;
    final fallbackProgress = _fallbackProgress(
      newStatus,
      isCourier: requestType == 'COURIER',
      completedStops: completedCourierStops,
      totalStops: totalCourierStops,
    );

    setState(() {
      _tripStatus = newStatus;
      _requestType = requestType;
      _driverConnected = data['driverConnected'] as bool? ?? driverLoc.isNotEmpty || driver.isNotEmpty;
      _driverName = _resolveDriverName(driver);
      _driverPhone = _resolveDriverPhone(driver);
      _totalFarePrice = _asText(fare['totalFare']) ??
          _asText(metrics['estimatedFare']) ??
          (_requestDetails?.actualFare != null ? _requestDetails!.actualFare!.toStringAsFixed(0) : '');
      _pickupAddress = pickupAddress?.isNotEmpty == true
          ? pickupAddress!
          : (_pickupAddress.isNotEmpty
              ? _pickupAddress
              : widget.originLocation ?? '');
      _dropoffAddress = dropoffAddress?.isNotEmpty == true
          ? dropoffAddress!
          : (_dropoffAddress.isNotEmpty
              ? _dropoffAddress
              : widget.destinationLocation ?? '');

      final pickupLatitude = _asDouble(pickup['latitude']);
      final pickupLongitude = _asDouble(pickup['longitude']);
      if (_hasCoordinates(pickupLatitude, pickupLongitude)) {
        _pickupPosition = LatLng(
          pickupLatitude!,
          pickupLongitude!,
        );
      }
      final dropoffLatitude = _asDouble(dropoff['latitude']);
      final dropoffLongitude = _asDouble(dropoff['longitude']);
      if (_hasCoordinates(dropoffLatitude, dropoffLongitude)) {
        _dropoffPosition = LatLng(
          dropoffLatitude!,
          dropoffLongitude!,
        );
      }

      if (realtimeRouteStops.isNotEmpty) {
        _routeStops = realtimeRouteStops;
        _pickupPosition = realtimeRouteStops.first.position;
        _dropoffPosition = realtimeRouteStops.last.position;
        _pickupAddress = realtimeRouteStops.first.title;
        _dropoffAddress = realtimeRouteStops.last.title;
      }

      _distance = _fmtDist(remainingDistance ?? 0);
      _duration = _fmtDur(estimatedDuration);
      _eta = _asText(metrics['estimatedArrival']) ?? _eta;
      _progress = remainingDistance != null && initialDistance > 0
          ? ((initialDistance - remainingDistance) / initialDistance).clamp(0.0, 1.0)
          : fallbackProgress;

      if (driverLoc.isNotEmpty) {
        _driverPosition = LatLng(
          (_asDouble(driverLoc['latitude']) ?? _driverPosition?.latitude ?? 0),
          (_asDouble(driverLoc['longitude']) ?? _driverPosition?.longitude ?? 0),
        );
        _driverBearing = _asDouble(driverLoc['bearing']) ?? 0;
        _driverSpeed = _asDouble(driverLoc['speed']) ?? 0;
      }
    });

    _seedFallbackRouteStopsFromRealtime();

    if (prevStatus != newStatus) _onStatusChanged(newStatus);

    _refreshMapMarkers();

    // FIX: draw route once pickup & dropoff are known
    // Draws pickup → dropoff (the full client journey)
    if (!_routeDrawn &&
        _pickupPosition.latitude  != 0 &&
        _dropoffPosition.latitude != 0) {
      _routeDrawn = true;
      _drawFullRoute();
    }
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> d) {
    if (!mounted) return;
    final newPos = LatLng(
      (d['latitude']  as num).toDouble(),
      (d['longitude'] as num).toDouble(),
    );

    // Ignore micro-updates < 3m
    if (_driverPosition != null) {
      final dist = Geolocator.distanceBetween(
        _driverPosition!.latitude, _driverPosition!.longitude,
        newPos.latitude,           newPos.longitude,
      );
      if (dist < 3) return;
    }

    setState(() {
      _driverPosition = newPos;
      _driverBearing  = (d['bearing'] as num?)?.toDouble() ?? _driverBearing;
      _driverSpeed    = (d['speed']   as num?)?.toDouble() ?? _driverSpeed;
    });
    _refreshMapMarkers();
    _refreshDriverConnectorPolyline();
  }

  void _onStatusChanged(String status) {
    HapticFeedback.mediumImpact();
    switch (status) {
      case 'completed':
        _showCompletionSheet();
        break;
      case 'cancelled':
      case 'cancelled_by_client':
        _showCancellationDialog();
        break;
      case 'arrived_at_pickup':
        _showDriverArrivedSnack();
        break;
      // When trip starts, redraw route from pickup to dropoff
      case 'client_on_board':
        _routeDrawn = false;
        _drawFullRoute();
        break;
    }
  }

  String _normalizeStatus(String? rawStatus) {
    switch (rawStatus?.toUpperCase()) {
      case 'DRIVER_ARRIVING':
        return 'driver_arriving';
      case 'ARRIVED_AT_PICKUP':
        return 'arrived_at_pickup';
      case 'CLIENT_ON_BOARD':
      case 'IN_PROGRESS':
      case 'ONGOING':
        return 'client_on_board';
      case 'COMPLETED':
        return 'completed';
      case 'CANCELLED':
        return 'cancelled';
      case 'CANCELLED_BY_CLIENT':
        return 'cancelled_by_client';
      case 'STARTED':
      case 'ACCEPTED':
      case 'APPROVED':
      case 'ASSIGNED':
      case 'SEARCHING_DRIVER':
      case 'PENDING':
        return 'started';
      default:
        return rawStatus?.toLowerCase() ?? 'started';
    }
  }

  List<_RouteStopData> _buildRouteStops(RequestContent request) {
    final rawStops = <_RouteStopData>[];

    if (request.isCourier) {
      final from = request.courierFrom;
      if (_hasCoordinates(from?.latitude, from?.longitude)) {
        rawStops.add(_RouteStopData(
          id: 'origin',
          title: from?.name ?? request.originName,
          position: LatLng(from!.latitude!, from.longitude!),
          type: _RouteStopType.origin,
          order: 0,
          isCompleted: true,
          subtitle: from.receiverName,
        ));
      }

      final checkpoints = List<CourierCheckpoint>.from(request.courierCheckpoints)
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      for (final checkpoint in checkpoints) {
        if (!_hasCoordinates(checkpoint.latitude, checkpoint.longitude)) continue;
        rawStops.add(_RouteStopData(
          id: 'checkpoint_${checkpoint.order ?? rawStops.length}',
          title: checkpoint.name ?? 'Checkpoint',
          position: LatLng(checkpoint.latitude!, checkpoint.longitude!),
          type: _RouteStopType.checkpoint,
          order: checkpoint.order ?? rawStops.length,
          isCompleted: checkpoint.checkpointStatus?.toUpperCase() == 'COMPLETED',
          subtitle: checkpoint.receiverName ?? checkpoint.checkpointStatus,
        ));
      }

      final to = request.courierTo;
      if (_hasCoordinates(to?.latitude, to?.longitude)) {
        rawStops.add(_RouteStopData(
          id: 'destination',
          title: to?.name ?? request.destinationLocation ?? 'Destination',
          position: LatLng(to!.latitude!, to.longitude!),
          type: _RouteStopType.destination,
          order: (rawStops.isEmpty ? 0 : rawStops.last.order + 1),
          isCompleted: _normalizeStatus(request.status) == 'completed',
          subtitle: to.receiverName,
        ));
      }
    } else {
      final origin = request.originLocation;
      if (_hasCoordinates(origin?.latitude, origin?.longitude)) {
        rawStops.add(_RouteStopData(
          id: 'origin',
          title: origin?.name ?? 'Pickup',
          position: LatLng(origin!.latitude!, origin.longitude!),
          type: _RouteStopType.origin,
          order: 0,
          isCompleted: _tripStatus == 'client_on_board' || _tripStatus == 'completed',
        ));
      }

      final checkpoints = List<Checkpoint>.from(request.checkpoints)
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      for (final checkpoint in checkpoints) {
        if (!_hasCoordinates(checkpoint.latitude, checkpoint.longitude)) continue;
        rawStops.add(_RouteStopData(
          id: 'checkpoint_${checkpoint.order ?? rawStops.length}',
          title: checkpoint.name ?? 'Checkpoint',
          position: LatLng(checkpoint.latitude!, checkpoint.longitude!),
          type: _RouteStopType.checkpoint,
          order: checkpoint.order ?? rawStops.length,
        ));
      }
    }

    return _dedupeStops(rawStops);
  }

  List<_RouteStopData> _dedupeStops(List<_RouteStopData> stops) {
    final unique = <_RouteStopData>[];
    for (final stop in stops) {
      if (unique.isEmpty) {
        unique.add(stop);
        continue;
      }
      final last = unique.last;
      if (_sameCoordinate(last.position, stop.position) ||
          last.title.trim().toLowerCase() == stop.title.trim().toLowerCase()) {
        unique[unique.length - 1] = _RouteStopData(
          id: last.id,
          title: stop.title,
          position: stop.position,
          type: stop.type,
          order: stop.order,
          isCompleted: last.isCompleted || stop.isCompleted,
          subtitle: stop.subtitle ?? last.subtitle,
        );
        continue;
      }
      unique.add(stop);
    }
    return unique;
  }

  bool _hasCoordinates(double? latitude, double? longitude) {
    return latitude != null && longitude != null;
  }

  bool _sameCoordinate(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.00001 &&
        (a.longitude - b.longitude).abs() < 0.00001;
  }

  void _syncAnchorsFromStops() {
    if (_routeStops.isEmpty) return;
    setState(() {
      _pickupPosition = _routeStops.first.position;
      _dropoffPosition = _routeStops.last.position;
      _pickupAddress = _routeStops.first.title;
      _dropoffAddress = _routeStops.last.title;
    });
  }

  void _seedFallbackRouteStopsFromRealtime() {
    if (_routeStops.isNotEmpty) {
      final needsDestinationStop =
          _dropoffPosition.latitude != 0 &&
          (_routeStops.last.type != _RouteStopType.destination ||
              !_sameCoordinate(_routeStops.last.position, _dropoffPosition));
      if (needsDestinationStop) {
        final updatedStops = List<_RouteStopData>.from(_routeStops)
          ..add(_RouteStopData(
            id: 'destination',
            title: _dropoffAddress.isNotEmpty ? _dropoffAddress : 'Destination',
            position: _dropoffPosition,
            type: _RouteStopType.destination,
            order: 1,
            isCompleted: _tripStatus == 'completed',
          ));
        setState(() {
          _routeStops = _dedupeStops(updatedStops);
        });
      }
      return;
    }

    if (_pickupPosition.latitude == 0 || _dropoffPosition.latitude == 0) return;

    setState(() {
      _routeStops = [
        _RouteStopData(
          id: 'origin',
          title: _pickupAddress.isNotEmpty ? _pickupAddress : widget.originLocation ?? 'Pickup',
          position: _pickupPosition,
          type: _RouteStopType.origin,
          order: 0,
        ),
        _RouteStopData(
          id: 'destination',
          title: _dropoffAddress.isNotEmpty
              ? _dropoffAddress
              : widget.destinationLocation ?? 'Destination',
          position: _dropoffPosition,
          type: _RouteStopType.destination,
          order: 1,
          isCompleted: _tripStatus == 'completed',
        ),
      ];
    });
  }

  int _resolveActiveRouteIndex() {
    if (_routeStops.isEmpty) return 0;

    if (_isCourier) {
      final firstPending = _routeStops.indexWhere(
        (stop) => stop.type != _RouteStopType.origin && !stop.isCompleted,
      );
      return firstPending == -1 ? _routeStops.length - 1 : firstPending;
    }

    switch (_tripStatus) {
      case 'client_on_board':
        return _routeStops.length > 1 ? 1 : 0;
      case 'completed':
        return _routeStops.length - 1;
      default:
        return 0;
    }
  }

  // ─── Map Markers ─────────────────────────────────────────────────────────
  // FIX: markers only shown when their LatLng is valid (non-zero)
  // FIX: anchor set correctly for teardrop markers (bottom-center = 0.5, 1.0)
  void _refreshMapMarkers() {
    if (!mounted) return;
    final marks   = <Marker>{};
    final circles = <Circle>{};
    final nextStop = _nextStop;

    // ── Pickup marker (hide once client is on board) ──────────────────────
    final bool showPickup = _pickupPosition.latitude  != 0 &&
        _tripStatus != 'client_on_board' &&
        _tripStatus != 'completed';

    if (showPickup && _clientIcon != null) {
      marks.add(Marker(
        markerId:   const MarkerId('pickup'),
        position:   _pickupPosition,
        icon:       _clientIcon!,
        // FIX: anchor at bottom-center so stem tip sits on the coordinate
        anchor:     const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: 'Your Pickup', snippet: _pickupAddress),
      ));
      circles.add(Circle(
        circleId:    const CircleId('pickupZone'),
        center:      _pickupPosition,
        radius:      55,
        fillColor:   _kGreen.withOpacity(0.10),
        strokeColor: _kGreen.withOpacity(0.40),
        strokeWidth: 2,
      ));
    }

    // ── Dropoff marker ────────────────────────────────────────────────────
    if (_dropoffPosition.latitude != 0 && _destIcon != null) {
      marks.add(Marker(
        markerId:   const MarkerId('dropoff'),
        position:   _dropoffPosition,
        icon:       _destIcon!,
        anchor:     const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: 'Destination', snippet: _dropoffAddress),
      ));
      circles.add(Circle(
        circleId:    const CircleId('dropoffZone'),
        center:      _dropoffPosition,
        radius:      55,
        fillColor:   _kRed.withOpacity(0.10),
        strokeColor: _kRed.withOpacity(0.40),
        strokeWidth: 2,
      ));
    }

    for (final stop in _routeStops.where((stop) => stop.type == _RouteStopType.checkpoint)) {
      final isNextStop = nextStop?.id == stop.id;
      marks.add(Marker(
        markerId: MarkerId(stop.id),
        position: stop.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          stop.isCompleted
              ? BitmapDescriptor.hueGreen
              : isNextStop
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: stop.title,
          snippet: stop.subtitle ?? (_isCourier ? 'Courier checkpoint' : 'Ride checkpoint'),
        ),
      ));
    }

    // ── Driver marker ─────────────────────────────────────────────────────
    if (_driverPosition != null && _driverIcon != null) {
      marks.add(Marker(
        markerId:   const MarkerId('driver'),
        position:   _driverPosition!,
        icon:       _driverIcon!,
        rotation:   _driverBearing,
        anchor:     const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title:   _driverName,
          snippet: '${(_driverSpeed * 3.6).toStringAsFixed(0)} km/h',
        ),
      ));
      // Pulsing accuracy circle around driver
      circles.add(Circle(
        circleId:    const CircleId('driverRadius'),
        center:      _driverPosition!,
        radius:      80,
        fillColor:   _kAmber.withOpacity(0.08),
        strokeColor: _kAmber.withOpacity(0.30),
        strokeWidth: 1,
      ));
    }

    setState(() {
      _markers..clear()..addAll(marks);
      _circles..clear()..addAll(circles);
    });
  }

  // ─── Route Drawing ───────────────────────────────────────────────────────
  // FIX: draws TWO polylines:
  //   1. Driver → Pickup  (amber dashed — where driver is heading)
  //   2. Pickup → Dropoff (accent solid — the client's full journey)
  // When client_on_board: only draws current driver position → dropoff
  Future<void> _drawFullRoute() async {
    if (_routeStops.length < 2) {
      _refreshDriverConnectorPolyline();
      return;
    }

    final apiKey = dotenv.get('apiKey');
    final newPolylines = <Polyline>{};
    final startIndex = _activeRouteIndex.clamp(0, _routeStops.length - 1);
    final routeWindow = _routeStops.sublist(startIndex);

    try {
      if (routeWindow.length >= 2) {
        final pickupToDropoff = await _fetchDirections(
          origin: routeWindow.first.position,
          destination: routeWindow.last.position,
          apiKey: apiKey,
          waypoints: routeWindow.length > 2
              ? routeWindow
                  .sublist(1, routeWindow.length - 1)
                  .map((stop) => stop.position)
                  .toList()
              : const [],
        );

        if (pickupToDropoff.isNotEmpty) {
          newPolylines.add(Polyline(
            polylineId: const PolylineId('journey'),
            points:     pickupToDropoff,
            color:      _kAccent,
            width:      6,
            startCap:   Cap.roundCap,
            endCap:     Cap.roundCap,
            geodesic:   true,
          ));
        }
      }

      final driverConnector = _buildDriverConnectorPolyline();
      if (driverConnector != null) {
        newPolylines.add(driverConnector);
      }

      if (!mounted) return;
      setState(() {
        _polylines..clear()..addAll(newPolylines);
      });
      _fitBounds();
      _routeDrawn = true;
    } catch (e) {
      if (kDebugMode) print('[Route] Error drawing route: $e');
    }
  }

  Polyline? _buildDriverConnectorPolyline() {
    final nextStop = _nextStop;
    if (_driverPosition == null || nextStop == null || _tripStatus == 'completed') {
      return null;
    }
    if (_sameCoordinate(_driverPosition!, nextStop.position)) {
      return null;
    }

    return Polyline(
      polylineId: const PolylineId('driver_connector'),
      points: [_driverPosition!, nextStop.position],
      color: _kAmber,
      width: 4,
      patterns: [PatternItem.dash(18), PatternItem.gap(10)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );
  }

  void _refreshDriverConnectorPolyline() {
    final driverConnector = _buildDriverConnectorPolyline();
    if (!mounted) return;

    setState(() {
      _polylines.removeWhere(
        (polyline) => polyline.polylineId.value == 'driver_connector',
      );
      if (driverConnector != null) {
        _polylines.add(driverConnector);
      }
    });
  }

  Future<List<LatLng>> _fetchDirections({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    List<LatLng> waypoints = const [],
  }) async {
    final waypointQuery = waypoints.isEmpty
        ? ''
        : '&waypoints=${Uri.encodeComponent(
            waypoints
                .map((point) => '${point.latitude},${point.longitude}')
                .join('|'),
          )}';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving$waypointQuery&key=$apiKey',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List? ?? [];
    if (routes.isEmpty) return [];
    final encoded = routes[0]['overview_polyline']['points'] as String;
    return _decodePolyline(encoded);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final pts = <LatLng>[];
    int i = 0, lat = 0, lng = 0;
    while (i < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      shift = 0; result = 0;
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

  void _fitBounds() {
    if (_mapController == null) return;
    final pts = <LatLng>[
      ..._routeStops.map((stop) => stop.position),
      if (_driverPosition != null)        _driverPosition!,
    ];
    if (pts.length < 2) {
      if (pts.isNotEmpty) {
        _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
                CameraPosition(target: pts.first, zoom: 15)));
      }
      return;
    }
    final lats = pts.map((p) => p.latitude).toList();
    final lngs = pts.map((p) => p.longitude).toList();
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

  // ─── Map Style ────────────────────────────────────────────────────────────
  // Lighter/cleaner style so markers pop against the map background
  final String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f7fa"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#012A4A"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#A9D6E5"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#e4eef5"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#89C2D9"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#61A5C2"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#A9D6E5"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';

  // ─── Utils ───────────────────────────────────────────────────────────────
  String _fmtDist(double m) {
    if (m <= 0) return '---';
    return m < 1000 ? '${m.toStringAsFixed(0)} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _fmtDur(int s) {
    if (s <= 0) return '---';
    final h = s ~/ 3600, m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m} min';
    return '<1 min';
  }

  void _callDriver() {
    if (_driverPhone.isNotEmpty) FlutterPhoneDirectCaller.callNumber('+$_driverPhone');
  }

  void _toggleBottomSheet() {
    setState(() {
      _isBottomSheetExpanded = !_isBottomSheetExpanded;
    });
  }

  // ─── Status Handlers ─────────────────────────────────────────────────────
  void _showDriverArrivedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kGreen,
      behavior:        SnackBarBehavior.floating,
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin:          const EdgeInsets.all(16),
      duration:        const Duration(seconds: 4),
      content: Row(children: [
        const Text('📍', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Driver has arrived!',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Head to your pickup point',
              style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.85))),
        ]),
      ]),
    ));
  }

  void _showCancellationDialog() {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon:    '❌',
        title:   'Trip Cancelled',
        message: 'This trip has been cancelled.',
        actions: [
          _DialogAction(label: 'Go Home', isPrimary: true, onTap: () {
            Navigator.pop(context);
            context.go('/');
          }),
        ],
      ),
    );
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context:              context,
      isScrollControlled:   true,
      backgroundColor:      Colors.transparent,
      builder: (_) => _RatingSheet(
        driverName: _driverName,
        totalPrice: _totalFarePrice,
        onRate: (stars, feedback) async {
          await _db.ref('active_trips/${widget.requestId}/rating').set({
            'stars':    stars,
            'feedback': feedback,
            'ratedAt':  DateTime.now().toIso8601String(),
          });
          if (mounted) context.go('/');
        },
        onSkip: () => context.go('/'),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final config = _currentStatusConfig;

    return Scaffold(
      backgroundColor: _kPrimary,
      body: Stack(
        children: [
          // ── Full-screen Google Map ────────────────────────────────────
          Positioned.fill(
            bottom: 0,
            child: RepaintBoundary(
              child: GoogleMap(
                onMapCreated: (ctrl) async {
                  _mapController = ctrl;
                  await ctrl.setMapStyle(_mapStyle);
                  setState(() => _mapReady = true);
                  Future.delayed(
                      const Duration(milliseconds: 600), _fitBounds);
                },
                markers:               _markers,
                polylines:             _polylines,
                circles:               _circles,
                initialCameraPosition: CameraPosition(target: _clientPosition, zoom: 14),
                myLocationEnabled:     false,
                zoomControlsEnabled:   false,
                compassEnabled:        false,
                mapToolbarEnabled:     false,
                buildingsEnabled:      true,
                // Give bottom panel enough room so markers aren't hidden
                padding: EdgeInsets.only(bottom: _bottomSheetMapPadding),
              ),
            ),
          ),

          // ── Bottom panel glass blur gradient ──────────────────────────
          Positioned(
            left: 0, right: 0, bottom: _bottomSheetGradientBottom, height: 70,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [Colors.transparent, _kSurface.withOpacity(0.95)],
                ),
              ),
            ),
          ),

          // ── App Bar ──────────────────────────────────────────────────
          _buildAppBar(config),

          // ── LIVE badge ───────────────────────────────────────────────
          Positioned(top: 108, right: 16, child: _buildLiveBadge()),

          // ── Recenter FAB ─────────────────────────────────────────────
          Positioned(
            bottom: _bottomSheetFabBottom, right: 16,
            child: _buildFab(Icons.my_location_rounded, _fitBounds),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildBottomPanel(config),
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  _StatusConfig get _currentStatusConfig {
    if (!_isCourier) {
      return _rideStatusConfigs[_tripStatus] ??
          const _StatusConfig('🚗', 'Tracking', 'Your trip is active', _kAccent);
    }

    switch (_tripStatus) {
      case 'completed':
        return const _StatusConfig(
          '📦',
          'Courier Delivered',
          'All courier checkpoints have been completed',
          _kGreen,
        );
      case 'client_on_board':
        if (_completedCourierStops > 0) {
          return _StatusConfig(
            '🛵',
            'Deliveries In Progress',
            'Completed $_completedCourierStops of $_totalCourierStops delivery stops',
            _kAccent,
          );
        }
        return const _StatusConfig(
          '🛵',
          'Courier In Transit',
          'Your package is on the way to the delivery stops',
          _kAccent,
        );
      case 'arrived_at_pickup':
        return const _StatusConfig(
          '📦',
          'Package Collected',
          'The courier has collected the package from the sender',
          _kGreen,
        );
      case 'driver_arriving':
        return const _StatusConfig(
          '🛵',
          'Courier Heading To Pickup',
          'The courier is on the way to collect your package',
          _kAmber,
        );
      case 'cancelled':
      case 'cancelled_by_client':
        return const _StatusConfig(
          '❌',
          'Courier Cancelled',
          'This delivery request has been cancelled',
          Colors.red,
        );
      case 'started':
      default:
        if (_courierDriverApproved) {
          return const _StatusConfig(
            '✅',
            'Courier Approved',
            'A courier accepted your delivery and is preparing collection',
            _kGreen,
          );
        }
        return const _StatusConfig(
          '⏳',
          'Waiting For Courier',
          'Your delivery request is approved and awaiting collection',
          _kAmber,
        );
    }
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────
  Widget _buildAppBar(_StatusConfig config) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [_kPrimary.withOpacity(0.96), _kAccent.withOpacity(0.88)],
              ),
              boxShadow: [
                BoxShadow(color: _kAccent.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        // Text(config.emoji, style: const TextStyle(fontSize: 16)),
                        // const SizedBox(width: 6),
                        Text(config.title,
                            style: GoogleFonts.dmSans(
                                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                      const SizedBox(height: 2),
                      Text(config.subtitle,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: Colors.white.withOpacity(0.72))),
                    ]),
                  ),
                  // Connection status dot
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _driverConnected ? _kGreen : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_driverConnected ? _kGreen : Colors.orange).withOpacity(0.5),
                          blurRadius: 6, spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── LIVE Badge ───────────────────────────────────────────────────────────
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
              BoxShadow(color: _kGreen.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: _kGreen, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.6), blurRadius: 4, spreadRadius: 2)],
              ),
            ),
            const SizedBox(width: 5),
            Text('LIVE',
                style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: _kPrimary, letterSpacing: 1.2)),
          ]),
        ),
      ),
    );
  }

  Widget _buildFab(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: _kPrimary, size: 22),
      ),
    );
  }

  // ─── Bottom Panel ─────────────────────────────────────────────────────────
  Widget _buildBottomPanel(_StatusConfig config) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Container(
      constraints: BoxConstraints(minHeight: _isBottomSheetExpanded ? 300 : 148),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 28, offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleBottomSheet,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _isBottomSheetExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(children: [
              _buildBottomSheetHeader(config),
              const SizedBox(height: 14),
              if (_isBottomSheetExpanded) ...[
                _buildStatusStepper(),
                if (!_isCourier) ...[
                  const SizedBox(height: 14),
                  _buildMetricsRow(),
                ],
                const SizedBox(height: 14),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildRoutePreview(),
                const SizedBox(height: 16),
              ] else ...[
                _buildCollapsedPanelSummary(config),
                const SizedBox(height: 16),
              ],
              _buildDriverCard(),
            ]),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    ),
    );
  }

  Widget _buildBottomSheetHeader(_StatusConfig config) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCourier ? 'Courier Details' : 'Trip Details',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isBottomSheetExpanded
                    ? 'Tap the handle to collapse this panel'
                    : 'Tap the handle to view more info',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _isCourier ? 'COURIER' : 'RIDE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: config.color,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedPanelSummary(_StatusConfig config) {
    final nextStop = _nextStop;
    final totalTaskStops = _routeStops.where((stop) => stop.type != _RouteStopType.origin).length;
    final completedTaskStops = _routeStops
        .where((stop) => stop.type != _RouteStopType.origin && stop.isCompleted)
        .length;

    final summaryValue = _isCourier
        ? '$completedTaskStops/$totalTaskStops stops completed'
        : '${(_progress * 100).toStringAsFixed(0)}% complete';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.color.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.alt_route_rounded, color: config.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextStop != null ? 'Next stop: ${nextStop.title}' : 'Route information',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summaryValue,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Stepper ──────────────────────────────────────────────────────
  Widget _buildStatusStepper() {
    final steps = _isCourier ? _courierFlowSteps : _rideFlowSteps;
    final currentStep = _isCourier
        ? _currentCourierStepIndex
        : _currentRideStepIndex;

    return Row(
      children: List.generate(steps.length, (i) {
        final done   = i <= currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: active ? 36 : 28, height: active ? 36 : 28,
                  decoration: BoxDecoration(
                    color: done ? _kAccent : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Icon(steps[i].icon,
                      size: active ? 18 : 14,
                      color: done ? Colors.white : Colors.grey.shade400),
                ),
                const SizedBox(height: 4),
                Text(steps[i].label,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: done ? _kPrimary : Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center),
              ]),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: 2,
                  color: i < currentStep ? _kAccent : Colors.grey.shade200,
                ),
              ),
          ]),
        );
      }),
    );
  }

  int get _currentRideStepIndex {
    const statusKeys = [
      'started',
      'driver_arriving',
      'arrived_at_pickup',
      'client_on_board',
      'completed'
    ];
    return statusKeys.indexOf(_tripStatus).clamp(0, statusKeys.length - 1);
  }

  int get _currentCourierStepIndex {
    if (_tripStatus == 'completed') return 4;
    if (_tripStatus == 'cancelled' || _tripStatus == 'cancelled_by_client') return 0;

    if (_completedCourierStops > 0) {
      return 3;
    }

    if (_tripStatus == 'client_on_board') {
      return 2;
    }

    if (_tripStatus == 'arrived_at_pickup') {
      return 1;
    }

    if (_tripStatus == 'driver_arriving') {
      return 1;
    }

    if (_courierDriverApproved) {
      return 1;
    }

    return 0;
  }

  Widget _buildMetricsRow() {
    return Row(children: [
      _MetricCard(icon: Icons.straighten_rounded, label: 'Distance', value: _distance, color: _kAccent),
      const SizedBox(width: 10),
      _MetricCard(icon: Icons.timer_outlined,     label: 'ETA',      value: _duration, color: _kAmber),
      const SizedBox(width: 10),
      _MetricCard(icon: Icons.schedule_rounded,   label: 'Arrives',  value: _eta,      color: _kGreen),
    ]);
  }

  Widget _buildProgressBar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Trip Progress',
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text('${(_progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kAccent, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value:            _progress,
          backgroundColor:  Colors.grey.shade200,
          valueColor:       AlwaysStoppedAnimation<Color>(_kAccent),
          minHeight:        7,
        ),
      ),
    ]);
  }

  // ─── Route Preview Strip ──────────────────────────────────────────────────
  Widget _buildRoutePreview() {
    final stops = _routeStops;
    final visibleStops = stops.take(4).toList();
    final hiddenCount = stops.length - visibleStops.length;

    if (stops.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Route details are loading...',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        _kSurface,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (_isCourier ? _kAmber : _kAccent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isCourier ? 'COURIER' : 'RIDE',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _isCourier ? _kAmber : _kAccent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _nextStop != null ? 'Next: ${_nextStop!.title}' : 'Route Overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              Text(
                '${stops.length} stops',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(visibleStops.length, (index) {
            final stop = visibleStops[index];
            final isNext = _nextStop?.id == stop.id;
            final connectorColor = stop.type == _RouteStopType.destination
                ? _kRed
                : stop.type == _RouteStopType.origin
                    ? _kGreen
                    : (stop.isCompleted ? _kGreen : _kAmber);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: connectorColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: connectorColor.withOpacity(0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (index < visibleStops.length - 1)
                      Container(
                        width: 2,
                        height: 26,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                            ),
                            if (isNext)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kAmber.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'NEXT',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _kAmber,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _routeStopLabel(stop),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: connectorColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (stop.subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            stop.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                '+$hiddenCount more stops on this request',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _routeStopLabel(_RouteStopData stop) {
    switch (stop.type) {
      case _RouteStopType.origin:
        return _isCourier ? 'COLLECTION' : 'PICKUP';
      case _RouteStopType.checkpoint:
        return _isCourier
            ? 'CHECKPOINT ${stop.order}'
            : 'STOP ${stop.order}';
      case _RouteStopType.destination:
        return _isCourier ? 'FINAL DROP-OFF' : 'DESTINATION';
    }
  }

  // ─── Driver Card ──────────────────────────────────────────────────────────
  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent.withOpacity(0.88)],
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _kAccent.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color:  Colors.white.withOpacity(0.15),
            shape:  BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR DRIVER',
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: Colors.white.withOpacity(0.65),
                    letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            Text(
              _driverName.isNotEmpty ? _driverName : 'Driver',
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _driverConnected ? _kGreen : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _driverConnected
                    ? '${(_driverSpeed * 3.6).toStringAsFixed(0)} km/h • Online'
                    : 'Connecting...',
                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.72)),
              ),
            ]),
          ]),
        ),

        // Animated call button
        AnimatedBuilder(
          animation: _driverPulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _driverPulseAnim.value,
            child: GestureDetector(
              onTap: _callDriver,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _kGreen, shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _kGreen.withOpacity(0.55), blurRadius: 12, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Loading Overlay ──────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: _kPrimary.withOpacity(0.82),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, -_bounceAnim.value),
                child: Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    color: _kAccent, shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _kAccent.withOpacity(0.55), blurRadius: 24, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 38),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text('Connecting to driver...',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Setting up live tracking',
                style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.58), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;

  const _MetricCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(0.20)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ─── Rating Sheet ─────────────────────────────────────────────────────────────
class _RatingSheet extends StatefulWidget {
  final String driverName, totalPrice;
  final void Function(int stars, String? feedback) onRate;
  final VoidCallback onSkip;

  const _RatingSheet({
    required this.driverName,
    required this.totalPrice,
    required this.onRate,
    required this.onSkip,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _ctrl = TextEditingController();
  final Set<String> _tags = {};

  final _quickTags = [
    '👍 Great Driver', '🚗 Smooth Ride', '⏱ On Time', '😊 Friendly', '🧹 Clean Car',
  ];

  String get _label {
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),

        // Trip summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimary.withOpacity(0.08), _kAccent.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPrimary.withOpacity(0.10)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trip Completed! 🏁',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              Text('with ${widget.driverName}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade600)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Total Fare',
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade500)),
              Text(
                widget.totalPrice.isNotEmpty ? '${widget.totalPrice} TZS' : 'N/A',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _kAccent),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 22),
        Text('How was your ride?',
            style: GoogleFonts.dmSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(_label, key: ValueKey(_stars),
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _stars > 0 ? _kAccent : Colors.grey.shade400)),
        ),
        const SizedBox(height: 16),

        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _stars = i + 1),
            child: AnimatedScale(
              scale:    i < _stars ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < _stars ? Colors.amber : Colors.grey.shade300,
                  size:  44,
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 18),

        if (_stars > 0) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text('What went well?',
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickTags.map((tag) {
              final sel = _tags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() => sel ? _tags.remove(tag) : _tags.add(tag)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _kAccent.withOpacity(0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: sel ? _kAccent : Colors.grey.shade200,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? _kAccent : Colors.grey.shade600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText:    'Leave a comment (optional)',
            hintStyle:   GoogleFonts.dmSans(color: Colors.grey.shade400, fontSize: 13),
            filled:      true,
            fillColor:   Colors.grey.shade50,
            border:      OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _kAccent, width: 1.5)),
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: Colors.grey.shade400),
          ),
          maxLines: 2,
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        const SizedBox(height: 20),

        Row(children: [
          OutlinedButton(
            onPressed: widget.onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              side:    BorderSide(color: Colors.grey.shade300),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Skip', style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _stars == 0 ? null : () {
                final tagFeedback = _tags.isNotEmpty ? _tags.join(', ') : null;
                final comment     = _ctrl.text.trim().isEmpty
                    ? tagFeedback
                    : '${_ctrl.text.trim()}${tagFeedback != null ? ' | $tagFeedback' : ''}';
                widget.onRate(_stars, comment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:         _kAccent,
                disabledBackgroundColor: Colors.grey.shade200,
                padding:  const EdgeInsets.symmetric(vertical: 14),
                shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Submit Rating',
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Styled Dialog ─────────────────────────────────────────────────────────────
class _StyledDialog extends StatelessWidget {
  final String icon, title, message;
  final List<_DialogAction> actions;

  const _StyledDialog({
    required this.icon, required this.title,
    required this.message, required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _kPrimary)),
          const SizedBox(height: 8),
          Text(message,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade600),
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
                  elevation:       0,
                  padding:         const EdgeInsets.symmetric(vertical: 14),
                  shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(a.label,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}

class _DialogAction {
  final String label;
  final bool   isPrimary;
  final VoidCallback onTap;
  const _DialogAction({required this.label, required this.onTap, this.isPrimary = false});
}