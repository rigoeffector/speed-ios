// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:speed_ios/api/auth.service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speed_ios/model/available.driver/available.driver.on.map.model.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/create_request_bloc.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_webservice/places.dart';

import '../../../utils/google_api_headers.dart';

class _RideAppColors {
  // Backgrounds
  static const bg = Color(0xFF0B1220);
  static const bg2 = Color(0xFF111827);
  static const bg3 = Color(0xFF1A2234);
  static const bg4 = Color(0xFF202B3F);

  // Brand Colors
  static const accent = Color(0xFF10B981);
  static const accent2 = Color(0xFF059669);
  static const green = Color(0xFF34D399);

  // Status Colors
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);

  // Text Colors
  static const txt = Color(0xFFF8FAFC);
  static const txt2 = Color(0xFFCBD5E1);
  static const txt3 = Color(0xFF94A3B8);

  // Borders
  static const border = Color(0x14FFFFFF);

  // Ride CTA
  static const gradientRide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );

  // Courier
  static const gradientCourier = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF134E4A),
      Color(0xFF10B981),
    ],
  );

  // Header
  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
      Color(0xFF134E4A),
    ],
  );
}

// ─── Payment Method Enum ────────────────────────────────────────────────────

enum PaymentMethod { cash, mobileMoney, card }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return greenColor;
      case PaymentMethod.mobileMoney:
        return orangeColor;
      case PaymentMethod.card:
        return primaryColor1;
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay with cash on arrival';
      case PaymentMethod.mobileMoney:
        return 'MTN, Airtel, or other mobile wallets';
      case PaymentMethod.card:
        return 'Visa, Mastercard, or debit card';
    }
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class RequestRideScreen extends StatefulWidget {
  final NearbyDriver driver;
  final String selectedService;
  final String currentAddress;
  final double sLat;
  final double sLng;
  final int userId;
  final String countryCode;
  // Optional: pre-fill destination from quick-destination tap
  final String? initialDestinationName;
  final double? initialDestinationLat;
  final double? initialDestinationLng;

  const RequestRideScreen({
    Key? key,
    required this.driver,
    required this.selectedService,
    required this.currentAddress,
    required this.sLat,
    required this.sLng,
    required this.userId,
    required this.countryCode,
    this.initialDestinationName,
    this.initialDestinationLat,
    this.initialDestinationLng,
  }) : super(key: key);

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen>
    with SingleTickerProviderStateMixin {
  // ── Wizard state ────────────────────────────────────────────────────────
  int _step = 0; // 0 = Trip Details, 1 = Payment
  late AnimationController _stepController;

  // ── Location state ──────────────────────────────────────────────────────
  late String _currentAddress;
  late double _sLat;
  late double _sLng;
  List<Map<String, dynamic>> _checkpoints = [];
  String _locationSelected = '';
  String _distanceOriginDestination = '';
  String _distancePrice = '0.0';
  String _selectedUnitPrice = '850';

  // ── Payment ─────────────────────────────────────────────────────────────
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  // ── Bloc ────────────────────────────────────────────────────────────────
  late CreateRequestBloc _createRequestBloc;
  Map<String, dynamic>? _lastSubmittedRequestBody;

  // ── Inline search ────────────────────────────────────────────────────────
  bool _isSearching = false;
  bool _isPickupSearch = false;
  int? _editingCheckpointIndex;
  List<Prediction> _suggestions = [];
  bool _searchLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  // ── Request type ────────────────────────────────────────────────────────
  String _requestType = 'RIDE';
  bool get _isCourier => _requestType == 'COURIER';
  int get _paymentStep => _isCourier ? 2 : 1;
  static const _courierAccent = Color(0xFF1FA24D);

  // ── Courier state ──────────────────────────────────────────────────────
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  bool _driverApprovalRequired = true;
  final _packageDescController = TextEditingController();
  final _packageWeightController = TextEditingController();
  final _packageDimsController = TextEditingController();
  final _declaredValueController = TextEditingController();
  final _specialInstrController = TextEditingController();
  List<Map<String, TextEditingController>> _cpControllers = [];
  List<bool> _cpRequiresApproval = [];
  List<List<File>> _cpImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  Color get _requestAccent => _isCourier ? _RideAppColors.amber : _RideAppColors.accent;
  Color get _requestAccentAlt => _isCourier ? const Color(0xFFE8A317) : _RideAppColors.accent2;
  bool get _hasHomePreselection =>
      widget.selectedService.isNotEmpty ||
      widget.currentAddress.isNotEmpty ||
      widget.initialDestinationName != null;
  String get _serviceLabel => _requestType == 'COURIER' ? 'Courier' : _requestType;
  int get _totalSteps => _isCourier ? 3 : 2;
  int get _currentStepNumber => _step + 1;
  String get _currentStepTitle {
    if (_step == 0) return 'Trip Details';
    if (_isCourier && _step == 1) return 'Courier Details';
    return 'Payment Method';
  }

  String get _currentStepDescription {
    if (_step == 0) {
      return 'Set the route, review the estimate, and confirm the trip structure.';
    }
    if (_isCourier && _step == 1) {
      return 'Capture sender, receiver, package, and approval details before payment.';
    }
    return 'Review the journey, choose a payment method, and submit the request.';
  }

  String get _nextStepTitle {
    if (_step == 0) return _isCourier ? 'Courier Details' : 'Payment Method';
    if (_isCourier && _step == 1) return 'Payment Method';
    return 'Ready to Confirm';
  }

  double get _stepProgress => _currentStepNumber / _totalSteps;
  LinearGradient get _requestGradient => _isCourier
      ? _RideAppColors.gradientCourier
      : _RideAppColors.gradientRide;
  BoxDecoration _surfaceDecoration({Color? borderColor, Gradient? gradient, Color? color}) {
    return BoxDecoration(
      color: color ?? _RideAppColors.bg3,
      gradient: gradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? _RideAppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required VoidCallback? onTap,
    IconData icon = Icons.arrow_forward_rounded,
    bool loading = false,
    Gradient? gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: _surfaceDecoration(
            gradient: loading ? null : (gradient ?? _requestGradient),
            color: loading ? _RideAppColors.bg4 : null,
            borderColor: loading
                ? _RideAppColors.border
                : _requestAccent.withOpacity(0.28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostAction({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: _surfaceDecoration(
              color: _RideAppColors.bg3,
              borderColor: _RideAppColors.border,
            ),
            child: Icon(icon, color: _RideAppColors.txt2, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildStepGuideCard({
    required String title,
    required String description,
    required String primaryMeta,
    required String secondaryMeta,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(
        borderColor: _requestAccent.withOpacity(0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _requestGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _RideAppColors.txt,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _RideAppColors.txt3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetaChip(Icons.checklist_rounded, primaryMeta)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetaChip(Icons.north_east_rounded, secondaryMeta)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.currentAddress;
    _sLat = widget.sLat;
    _sLng = widget.sLng;
    _requestType = widget.selectedService.isNotEmpty
        ? widget.selectedService.toUpperCase()
        : 'RIDE';
    _createRequestBloc =
        CreateRequestBloc(CreateRequestInitial(), AuthService());
    _stepController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _stepController.forward();
    // Pre-fill destination if provided (from quick-destination / favorites tap)
    if (widget.initialDestinationName != null &&
        widget.initialDestinationLat != null &&
        widget.initialDestinationLng != null) {
      _checkpoints = [
        {
          'name': widget.initialDestinationName!,
          'lat': widget.initialDestinationLat!,
          'lng': widget.initialDestinationLng!,
        }
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcDistance());
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _createRequestBloc.close();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _packageDescController.dispose();
    _packageWeightController.dispose();
    _packageDimsController.dispose();
    _declaredValueController.dispose();
    _specialInstrController.dispose();
    for (final group in _cpControllers) {
      for (final c in group.values) c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _recalcDistance() {
    if (_checkpoints.isEmpty) {
      setState(() {
        _distanceOriginDestination = '';
        _distancePrice = '0.0';
      });
      return;
    }

    double total = 0.0;
    double prevLat = _sLat, prevLng = _sLng;

    for (final cp in _checkpoints) {
      final lat = cp['lat'] as double;
      final lng = cp['lng'] as double;
      final meters =
          Geolocator.distanceBetween(prevLat, prevLng, lat, lng);
      total += meters / 1000;
      prevLat = lat;
      prevLng = lng;
    }

    total = (total * 10).roundToDouble() / 10;
    final unit = double.parse(_selectedUnitPrice);
    final price = (total * unit * 10).roundToDouble() / 10;

    setState(() {
      _distanceOriginDestination = total.toStringAsFixed(1);
      _distancePrice = price.toStringAsFixed(1);
      _locationSelected = _checkpoints.map((c) => c['name'] as String).join(' | ');
    });
  }

  void _syncCpControllers() {
    while (_cpControllers.length < _checkpoints.length) {
      _cpControllers.add({
        'receiverName': TextEditingController(),
        'receiverPhone': TextEditingController(),
        'packageDesc': TextEditingController(),
        'packageWeight': TextEditingController(),
        'specialInstr': TextEditingController(),
      });
      _cpRequiresApproval.add(true);
    }
    while (_cpImages.length < _checkpoints.length) {
      _cpImages.add([]);
    }
  }

  // ── Open inline search panel ────────────────────────────────────────────
  void _searchDestination({int? replaceIndex}) {
    setState(() {
      _isPickupSearch = false;
      _editingCheckpointIndex = replaceIndex;
      _isSearching = true;
      _searchController.clear();
      _suggestions = [];
    });
    Future.microtask(() => _searchFocus.requestFocus());
  }

  void _searchPickup() {
    setState(() {
      _isPickupSearch = true;
      _editingCheckpointIndex = null;
      _isSearching = true;
      _searchController.clear();
      _suggestions = [];
    });
    Future.microtask(() => _searchFocus.requestFocus());
  }

  // ── Autocomplete query ──────────────────────────────────────────────────
  Future<void> _queryAutocomplete(String input) async {
    _debounce?.cancel();
    if (input.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final headers = await GoogleApiHeaders.getHeaders();
        final places = GoogleMapsPlaces(
            apiKey: dotenv.get('apiKey'), apiHeaders: headers);
        final response = await places.autocomplete(
          input,
          types: [],
          components: [Component(Component.country, widget.countryCode)],
          language: 'en',
        );
        if (mounted) {
          setState(() {
            _suggestions =
                response.isOkay ? response.predictions : [];
            _searchLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _searchLoading = false);
        if (kDebugMode) print('Autocomplete error: $e');
      }
    });
  }

  // ── Handle place selection ──────────────────────────────────────────────
  Future<void> _onPlaceSelected(Prediction p) async {
    final wasPickup = _isPickupSearch;
    final editIdx = _editingCheckpointIndex;
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _suggestions = [];
      _searchLoading = false;
    });
    _searchFocus.unfocus();

    try {
      final headers = await GoogleApiHeaders.getHeaders();
      final plist = GoogleMapsPlaces(
          apiKey: dotenv.get('apiKey'), apiHeaders: headers);
      final detail =
          await plist.getDetailsByPlaceId(p.placeId ?? '0');
      final geo = detail.result.geometry!;

      if (wasPickup) {
        setState(() {
          _currentAddress = p.description.toString();
          _sLat = geo.location.lat;
          _sLng = geo.location.lng;
        });
        if (_checkpoints.isNotEmpty) _recalcDistance();
      } else {
        final stop = {
          'name': p.description.toString(),
          'lat': geo.location.lat,
          'lng': geo.location.lng,
        };
        setState(() {
          if (editIdx != null && editIdx < _checkpoints.length) {
            _checkpoints[editIdx] = stop;
          } else {
            _checkpoints.add(stop);
          }
        });
        _syncCpControllers();
        _recalcDistance();
      }
    } catch (e) {
      if (kDebugMode) print('Place detail error: $e');
    }
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  Map<String, dynamic> _buildFirebaseTripPayload(
    String requestId,
    Map<String, dynamic> requestBody,
  ) {
    final requestType = (requestBody['requestType']?.toString() ?? _requestType).toUpperCase();
    final pickupSource = _asStringKeyedMap(requestBody['originLocation']) ??
        _asStringKeyedMap(requestBody['courierFrom']) ??
        <String, dynamic>{};
    final checkpointList = (requestBody['checkpoints'] as List?)
            ?.map((entry) => _asStringKeyedMap(entry) ?? <String, dynamic>{})
            .where((entry) => entry.isNotEmpty)
            .toList() ??
        const <Map<String, dynamic>>[];
    final lastCheckpoint = checkpointList.isNotEmpty ? checkpointList.last : null;
    final destinationName = requestBody['destinationLocation']?.toString().trim().isNotEmpty == true
        ? requestBody['destinationLocation'].toString().trim()
        : lastCheckpoint?['name']?.toString() ?? '';

    return {
      'tripId': requestId,
      'requestId': requestId,
      'requestType': requestType,
      'status': requestBody['status']?.toString() ?? 'PENDING',
      'requestedTime': requestBody['requestedTime'],
      'createdAt': requestBody['createdAt'] ?? requestBody['requestedTime'],
      'updatedAt': requestBody['updatedAt'] ?? requestBody['requestedTime'],
      'paymentMethod': _paymentMethod.label,
      'clientConnected': false,
      'driverConnected': false,
      'client': requestBody['client'],
      'motorBiker': requestBody['motorBiker'],
      'pickup': {
        'address': pickupSource['name']?.toString() ?? _currentAddress,
        'latitude': pickupSource['latitude'] ?? _sLat,
        'longitude': pickupSource['longitude'] ?? _sLng,
      },
      'dropoff': {
        'address': destinationName,
        'latitude': lastCheckpoint?['latitude'],
        'longitude': lastCheckpoint?['longitude'],
      },
      'metrics': {
        'distanceKm': double.tryParse(_distanceOriginDestination) ?? 0.0,
        'farePerKm': double.tryParse(_selectedUnitPrice) ?? 0.0,
        'estimatedFare': double.tryParse(_distancePrice) ?? 0.0,
        'paymentMethod': _paymentMethod.label,
      },
      'fare': {
        'totalFare': _distancePrice,
        'farePerKm': _selectedUnitPrice,
        'totalDistance': _distanceOriginDestination,
        'paymentMethod': _paymentMethod.label,
      },
      'originLocation': requestBody['originLocation'] ?? requestBody['courierFrom'],
      'destinationLocation': destinationName,
      'checkpoints': checkpointList,
      'courierFrom': requestBody['courierFrom'],
      'packageDescription': requestBody['packageDescription'],
      'packageWeight': requestBody['packageWeight'],
      'packageDimensions': requestBody['packageDimensions'],
      'declaredValue': requestBody['declaredValue'],
      'specialInstructions': requestBody['specialInstructions'],
      'requestBody': requestBody,
    };
  }

  Future<void> _initFirebaseTrip(
    String requestId,
    Map<String, dynamic> requestBody,
  ) async {
    await FirebaseDatabase.instance
        .ref('active_trips/$requestId')
        .set(_buildFirebaseTripPayload(requestId, requestBody));
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _stepController.forward(from: 0);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _createRequestBloc,
      child: Scaffold(
        backgroundColor: _RideAppColors.bg,
        body: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(innerBoxIsScrolled),
              ],
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: _step == 0
                    ? _buildStep1(key: const ValueKey('step1'))
                    : (_isCourier && _step == 1)
                        ? _buildCourierStep(key: const ValueKey('courier'))
                        : _buildStep2(key: const ValueKey('step2')),
              ),
            ),
            if (_isSearching) _buildInlineSearch(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      stretch: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _RideAppColors.bg,
      expandedHeight: 265,
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: _RideAppColors.bg3.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _RideAppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _RideAppColors.txt,
              size: 16,
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: innerBoxIsScrolled ? 1 : 0.94,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStepTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _RideAppColors.txt,
                      ),
                    ),
                    Text(
                      'Step $_currentStepNumber of $_totalSteps',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _RideAppColors.txt3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _requestAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _requestAccent.withOpacity(0.22)),
                ),
                child: Text(
                  _serviceLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _requestAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildExpandedHeader(),
      ),
    );
  }

  Widget _buildExpandedHeader() {
    final initials = widget.driver.displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Container(
      decoration: const BoxDecoration(
        gradient: _RideAppColors.gradientHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 88, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _RideAppColors.bg3.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _RideAppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: _requestGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _requestAccent.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Driver',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _RideAppColors.txt3,
                                  ),
                                ),
                                Text(
                                  widget.driver.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _RideAppColors.txt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.driver.isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _RideAppColors.green.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _RideAppColors.green.withOpacity(0.28)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: _RideAppColors.green,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Available',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _RideAppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                 
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_requestType.toLowerCase()} service',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _RideAppColors.txt2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: anim, curve: Curves.easeOut)),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _currentStepTitle,
                            key: ValueKey(_step),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _RideAppColors.txt,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentStepDescription,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: _RideAppColors.txt2,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _RideAppColors.bg3.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _RideAppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'STEP',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _RideAppColors.txt3,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_currentStepNumber/$_totalSteps',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _RideAppColors.txt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final active = _step == index;
    final done = _step > index;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: done ? 28 : (active ? 28 : 24),
          height: done ? 28 : (active ? 28 : 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? _RideAppColors.green
                : active
                    ? _requestAccent
                    : _RideAppColors.bg3,
            border: Border.all(
              color: done
                  ? _RideAppColors.green
                  : active
                      ? _requestAccent
                      : _RideAppColors.border,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _RideAppColors.txt3,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? _requestAccent
                : done
                    ? _RideAppColors.green
                    : _RideAppColors.txt3,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int afterIndex) {
    final done = _step > afterIndex;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: done
              ? [_RideAppColors.green, _RideAppColors.green]
              : [
                  _RideAppColors.border,
                  _RideAppColors.border,
                ],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ─── Inline Search Overlay ────────────────────────────────────────────────

  Widget _buildInlineSearch() {
    final hint = _isPickupSearch ? 'Where are you now?' : 'Search destination...';

    return GestureDetector(
      // tap scrim to close
      onTap: () {
        setState(() {
          _isSearching = false;
          _suggestions = [];
          _searchLoading = false;
        });
        _searchFocus.unfocus();
      },
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            // prevent scrim tap propagating through panel
            onTap: () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: _RideAppColors.bg2,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: _RideAppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag handle ──
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _RideAppColors.txt3,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // ── Panel title ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isPickupSearch
                                ? _RideAppColors.green.withOpacity(0.12)
                                : _requestAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isPickupSearch
                                ? Icons.my_location_rounded
                                : Icons.location_on_rounded,
                            color: _isPickupSearch ? _RideAppColors.green : _requestAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPickupSearch
                                ? 'Change Pickup'
                                : _editingCheckpointIndex != null
                                    ? 'Change Destination'
                                    : 'Add Destination',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _RideAppColors.txt,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = false;
                              _suggestions = [];
                              _searchLoading = false;
                            });
                            _searchFocus.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _RideAppColors.bg3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: _RideAppColors.txt2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Search field ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _RideAppColors.bg3,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isPickupSearch
                              ? _RideAppColors.green.withOpacity(0.24)
                              : _requestAccent.withOpacity(0.24),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: _queryAutocomplete,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _RideAppColors.txt),
                        cursorColor: _isPickupSearch ? _RideAppColors.green : _requestAccent,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _RideAppColors.txt3),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _isPickupSearch
                                ? _RideAppColors.green.withOpacity(0.7)
                                : _requestAccent.withOpacity(0.7),
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _searchLoading = false;
                                    });
                                  },
                                  child: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                      color: _RideAppColors.txt3),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Results list ──
                  Flexible(
                    child: _searchLoading
                        ? _buildSearchShimmer()
                        : _suggestions.isEmpty
                            ? _buildSearchEmpty()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 4, 16, 16),
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                  color: _RideAppColors.border),
                                itemBuilder: (context, index) {
                                  final p = _suggestions[index];
                                  final main =
                                      p.structuredFormatting?.mainText ??
                                          p.description ??
                                          '';
                                  final secondary =
                                      p.structuredFormatting?.secondaryText ??
                                          '';
                                  return InkWell(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    onTap: () => _onPlaceSelected(p),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _isPickupSearch
                                                ? _RideAppColors.green
                                                      .withOpacity(0.08)
                                                : _requestAccent
                                                      .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                            ),
                                            child: Icon(
                                              Icons.place_rounded,
                                              color: _isPickupSearch
                                                  ? _RideAppColors.green
                                                  : _requestAccent,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  main,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: _RideAppColors.txt,
                                                  ),
                                                ),
                                                if (secondary.isNotEmpty)
                                                  Text(
                                                    secondary,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color: _RideAppColors.txt3,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                              Icons.north_west_rounded,
                                              size: 14,
                                              color: _RideAppColors.txt3),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

  Widget _buildSearchShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmpty() {
    final hasQuery = _searchController.text.trim().length >= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.keyboard_rounded,
            size: 40,
            color: _RideAppColors.txt3,
          ),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'No results found' : 'Start typing to search',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _RideAppColors.txt3,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ─── Step 1 ───────────────────────────────────────────────────────────────

  Widget _buildStep1({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasHomePreselection) ...[
            _buildPreselectionCard()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 18),
          ],
          _buildStepGuideCard(
            title: 'Build Your Route',
            description:
                'Confirm pickup, add all stops, and review the estimate before continuing.',
            primaryMeta: _checkpoints.isEmpty
                ? 'No stops added yet'
                : '${_checkpoints.length} stop${_checkpoints.length == 1 ? '' : 's'} ready',
            secondaryMeta: 'Next: $_nextStepTitle',
            icon: Icons.route_rounded,
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 40.ms)
              .slideY(begin: 0.04, end: 0),
          const SizedBox(height: 18),
          // Request type selector
          // _buildRequestTypeSelector()
          //     .animate()
          //     .fadeIn(duration: 300.ms)
          //     .slideY(begin: 0.06, end: 0),
          // const SizedBox(height: 20),

          // Pickup row
          _buildSectionLabel('PICKUP LOCATION'),
          const SizedBox(height: 8),
          _buildPickupCard()
              .animate()
              .fadeIn(duration: 300.ms, delay: 80.ms)
              .slideX(begin: 0.06, end: 0),
          const SizedBox(height: 16),

          // Destinations
          _buildSectionLabel('DESTINATIONS'),
          const SizedBox(height: 8),
          ..._buildDestinationList(),
          _buildAddCheckpointButton()
              .animate()
              .fadeIn(duration: 300.ms, delay: 180.ms),
          const SizedBox(height: 16),

          // Route timeline
          if (_checkpoints.isNotEmpty) ...[
            _buildRouteTimeline()
                .animate()
                .fadeIn(duration: 300.ms, delay: 220.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: 16),
          ],

          // Price card
          if (_checkpoints.isNotEmpty)
            _buildPriceCard()
                .animate()
                .fadeIn(duration: 300.ms, delay: 260.ms)
                .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1)),

          const SizedBox(height: 28),

          // Next button
          SizedBox(
            width: double.infinity,
            child: _buildPrimaryAction(
              label: _isCourier ? 'Next: Courier Details' : 'Next: Payment',
              onTap: () {
                if (_checkpoints.isEmpty) {
                  showErrorAlert('Please add at least one destination', context);
                  return;
                }
                _goToStep(1);
              },
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.12, end: 0),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPreselectionCard() {
    final destination = _checkpoints.isNotEmpty
        ? _checkpoints.first['name'] as String
        : (widget.initialDestinationName ?? 'Choose destination');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(
        borderColor: _requestAccent.withOpacity(0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: _requestGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-selected from Home',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _RideAppColors.txt,
                      ),
                    ),
                    Text(
                      'Review the route and adjust anything before confirming.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _RideAppColors.txt3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _requestAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _requestAccent.withOpacity(0.28)),
                ),
                child: Text(
                  _serviceLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _requestAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPreselectionRow(
            icon: Icons.my_location_rounded,
            iconColor: _RideAppColors.green,
            label: 'Pickup',
            value: _currentAddress.isNotEmpty ? _currentAddress : 'Use current location',
          ),
          const SizedBox(height: 10),
          _buildPreselectionRow(
            icon: Icons.location_on_rounded,
            iconColor: _requestAccent,
            label: 'Destination',
            value: destination,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetaChip(
                  Icons.person_pin_circle_rounded,
                  widget.driver.displayName,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetaChip(
                  Icons.route_rounded,
                  _distanceOriginDestination.isNotEmpty
                      ? '$_distanceOriginDestination km'
                      : 'Distance updates here',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreselectionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _RideAppColors.txt3,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _RideAppColors.txt,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _RideAppColors.bg4,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _RideAppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _requestAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _RideAppColors.txt2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard() {
    return GestureDetector(
      onTap: _searchPickup,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _surfaceDecoration(
          borderColor: _RideAppColors.green.withOpacity(0.28),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _RideAppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: _RideAppColors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _RideAppColors.txt3)),
                  Text(
                    _currentAddress.isNotEmpty
                        ? _currentAddress
                        : 'Tap to set pickup location',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _RideAppColors.txt),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_location_alt_rounded,
                color: _RideAppColors.txt3, size: 18),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDestinationList() {
    if (_checkpoints.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: _surfaceDecoration(
            borderColor: _requestAccent.withOpacity(0.22),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _requestAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: _requestAccent.withOpacity(0.8), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'No destinations added yet',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: _RideAppColors.txt3,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      for (int i = 0; i < _checkpoints.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: _surfaceDecoration(
            borderColor: _requestAccent.withOpacity(0.26),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: _requestGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${i + 1}',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _checkpoints[i]['name'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w500, color: _RideAppColors.txt),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _searchDestination(replaceIndex: i),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _requestAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded,
                          size: 14, color: _requestAccent),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (i < _cpControllers.length) {
                        final removed = _cpControllers.removeAt(i);
                        for (final c in removed.values) c.dispose();
                        _cpRequiresApproval.removeAt(i);
                      }
                      setState(() => _checkpoints.removeAt(i));
                      _recalcDistance();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _RideAppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: _RideAppColors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 250.ms, delay: (40 * i).ms)
            .slideX(begin: 0.05, end: 0, delay: (40 * i).ms),
    ];
  }

  Widget _buildAddCheckpointButton() {
    return GestureDetector(
      onTap: _searchDestination,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _surfaceDecoration(
          color: _requestAccent.withOpacity(0.08),
          borderColor: _requestAccent.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_rounded, color: _requestAccent, size: 15),
            const SizedBox(width: 8),
            Text(
              _checkpoints.isEmpty ? 'Add Destination' : 'Add Another Checkpoint',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _requestAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    final stops = [
      {'label': 'Pickup', 'address': _currentAddress, 'isPickup': true},
      for (final cp in _checkpoints)
        {'label': 'Checkpoint', 'address': cp['name'] as String, 'isPickup': false},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < stops.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? _RideAppColors.green.withOpacity(0.12)
                            : _requestAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        i == 0
                            ? Icons.my_location_rounded
                            : i == stops.length - 1
                                ? Icons.location_on_rounded
                                : Icons.circle,
                        size: i == 0 ? 14 : 12,
                        color: i == 0 ? _RideAppColors.green : _requestAccent,
                      ),
                    ),
                    if (i < stops.length - 1)
                      Container(
                        width: 2,
                        height: 26,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _RideAppColors.green.withOpacity(0.35),
                              _requestAccent.withOpacity(0.35),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stops[i]['label'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _RideAppColors.txt3,
                          ),
                        ),
                        Text(
                          stops[i]['address'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _RideAppColors.txt,
                          ),
                        ),
                        if (i < stops.length - 1)
                          const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _surfaceDecoration(
        gradient: _requestGradient,
        borderColor: _requestAccent.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Price',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(
                      '$_distancePrice TZS',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _priceChip(Icons.straighten_rounded,
                      '$_distanceOriginDestination km'),
                  const SizedBox(height: 4),
                  _priceChip(Icons.speed_rounded,
                      '$_selectedUnitPrice TZS/km'),
                ],
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildNegotiablePriceLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CC).withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              size: 16,
              color: Color(0xFFFFE082),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NEGOTIABLE PRICE',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFFFFF4CC),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Final fare can be discussed and agreed between the client and driver.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _RideAppColors.txt3,
        letterSpacing: 0.8,
      ),
    );
  }

  // ─── Request Type Selector ────────────────────────────────────────────────

  Widget _buildRequestTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _RideAppColors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RideAppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _typeOption('RIDE', Icons.two_wheeler_rounded)),
          const SizedBox(width: 4),
          Expanded(child: _typeOption('COURIER', Icons.local_shipping_rounded)),
        ],
      ),
    );
  }

  Widget _typeOption(String type, IconData icon) {
    final selected = _requestType == type;
    final color = type == 'COURIER' ? _RideAppColors.amber : _RideAppColors.accent;
    return GestureDetector(
      onTap: () => setState(() => _requestType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color, selected && type == 'COURIER' ? const Color(0xFFE8A317) : _RideAppColors.accent2])
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? color.withOpacity(0.2) : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.white : _RideAppColors.txt3),
            const SizedBox(width: 8),
            Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _RideAppColors.txt3,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Courier Step ─────────────────────────────────────────────────────────

  Widget _buildCourierStep({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepGuideCard(
            title: 'Package Handoff Details',
            description:
                'Define who sends, who receives, and what the driver is carrying at each stop.',
            primaryMeta: '${_checkpoints.length} checkpoint${_checkpoints.length == 1 ? '' : 's'} to complete',
            secondaryMeta: 'Next: $_nextStepTitle',
            icon: Icons.inventory_2_rounded,
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.04, end: 0),
          const SizedBox(height: 18),
          _buildSectionLabel('SENDER INFORMATION'),
          const SizedBox(height: 8),
          _buildCourierSenderCard()
              .animate()
              .fadeIn(duration: 300.ms, delay: 80.ms)
              .slideY(begin: 0.06, end: 0),
          const SizedBox(height: 20),

          _buildSectionLabel('CHECKPOINT RECEIVERS'),
          const SizedBox(height: 8),
          ..._buildCheckpointReceiverCards(),
          const SizedBox(height: 20),

          _buildSectionLabel('PACKAGE INFORMATION'),
          const SizedBox(height: 8),
          _buildPackageInfoCard()
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: 0.06, end: 0),
          const SizedBox(height: 28),

          // Back + Next
          Row(
            children: [
              _buildGhostAction(
                onTap: () => _goToStep(0),
                icon: Icons.arrow_back_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPrimaryAction(
                  label: 'Next: Payment',
                  onTap: () {
                    _syncCpControllers();
                    for (int i = 0; i < _checkpoints.length; i++) {
                      if (i >= _cpImages.length || _cpImages[i].length < 2) {
                        showErrorAlert(
                          'Please add at least 2 package photos for Checkpoint ${i + 1}',
                          context,
                        );
                        return;
                      }
                    }
                    _goToStep(2);
                  },
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.12, end: 0),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCourierSenderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(
        borderColor: _RideAppColors.amber.withOpacity(0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _RideAppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warehouse_rounded,
                    color: _RideAppColors.amber, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup / Sender',
                      style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                        color: _RideAppColors.txt)),
                    Text(_currentAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10, color: _RideAppColors.txt3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCourierField(
            controller: _senderNameController,
            label: 'Sender / Contact Name',
            icon: Icons.person_rounded,
            hint: 'e.g. Warehouse Manager',
          ),
          _buildCourierField(
            controller: _senderPhoneController,
            label: 'Sender Phone',
            icon: Icons.phone_rounded,
            hint: '+250788123456',
            keyboardType: TextInputType.phone,
          ),
          SwitchListTile(
            value: _driverApprovalRequired,
            onChanged: (v) =>
                setState(() => _driverApprovalRequired = v),
            title: Text('Driver Approval Required',
              style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                color: _RideAppColors.txt)),
            subtitle: Text('Driver must confirm pickup',
              style: GoogleFonts.dmSans(
                fontSize: 10, color: _RideAppColors.txt3)),
            activeColor: _RideAppColors.amber,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCheckpointReceiverCards() {
    _syncCpControllers();
    return [
      for (int i = 0; i < _checkpoints.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: _surfaceDecoration(
            borderColor: _RideAppColors.amber.withOpacity(0.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: _requestGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checkpoint ${i + 1}',
                          style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                            color: _RideAppColors.txt)),
                        Text(_checkpoints[i]['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 10, color: _RideAppColors.txt3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCourierField(
                controller: _cpControllers[i]['receiverName']!,
                label: 'Receiver Name',
                icon: Icons.person_pin_rounded,
                hint: 'e.g. John Doe',
              ),
              _buildCourierField(
                controller: _cpControllers[i]['receiverPhone']!,
                label: 'Receiver Phone',
                icon: Icons.phone_rounded,
                hint: '+250785194263',
                keyboardType: TextInputType.phone,
              ),
              SwitchListTile(
                value: _cpRequiresApproval[i],
                onChanged: (v) =>
                    setState(() => _cpRequiresApproval[i] = v),
                title: Text('Requires Receiver Approval',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _RideAppColors.txt)),
                activeColor: _RideAppColors.amber,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              Divider(height: 16, color: _RideAppColors.border),
              _buildCourierField(
                controller: _cpControllers[i]['packageDesc']!,
                label: 'Package Description',
                icon: Icons.inventory_2_rounded,
                hint: 'e.g. Documents',
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildCourierField(
                      controller: _cpControllers[i]['packageWeight']!,
                      label: 'Weight',
                      icon: Icons.scale_rounded,
                      hint: 'e.g. 2kg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCourierField(
                      controller: _cpControllers[i]['specialInstr']!,
                      label: 'Instructions',
                      icon: Icons.info_outline_rounded,
                      hint: 'Handle with care',
                    ),
                  ),
                ],
              ),
              _buildCheckpointImages(i),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: (60 * i).ms)
            .slideX(begin: 0.05, end: 0, delay: (60 * i).ms),
    ];
  }

  Widget _buildPackageInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(
        borderColor: _RideAppColors.amber.withOpacity(0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _RideAppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_rounded,
                    color: _RideAppColors.amber, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Package Overview',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _RideAppColors.txt)),
            ],
          ),
          const SizedBox(height: 14),
          _buildCourierField(
            controller: _packageDescController,
            label: 'Package Description',
            icon: Icons.description_rounded,
            hint: 'e.g. Important documents',
          ),
          Row(
            children: [
              Expanded(
                child: _buildCourierField(
                  controller: _packageWeightController,
                  label: 'Weight',
                  icon: Icons.scale_rounded,
                  hint: 'e.g. 2kg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCourierField(
                  controller: _packageDimsController,
                  label: 'Dimensions',
                  icon: Icons.straighten_rounded,
                  hint: '30x20x10 cm',
                ),
              ),
            ],
          ),
          _buildCourierField(
            controller: _declaredValueController,
            label: 'Declared Value (TZS)',
            icon: Icons.attach_money_rounded,
            hint: '0.0',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          _buildCourierField(
            controller: _specialInstrController,
            label: 'Special Instructions',
            icon: Icons.warning_amber_rounded,
            hint: 'e.g. Fragile items',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCourierField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.dmSans(fontSize: 13, color: _RideAppColors.txt),
        cursorColor: _RideAppColors.amber,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.dmSans(fontSize: 12, color: _RideAppColors.txt3),
          hintStyle: GoogleFonts.dmSans(fontSize: 12, color: _RideAppColors.txt3),
          prefixIcon: Icon(icon,
              size: 18, color: _RideAppColors.amber.withOpacity(0.8)),
          filled: true,
          fillColor: _RideAppColors.bg4,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _RideAppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _RideAppColors.amber, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Image Capture Helpers ────────────────────────────────────────────────

  Future<void> _pickCheckpointImage(int cpIndex) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildImageSourceSheet(ctx),
    );
    if (source == null) return;
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _cpImages[cpIndex].add(File(picked.path)));
    }
  }

  Widget _buildImageSourceSheet(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RideAppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RideAppColors.border),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _RideAppColors.txt3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Package Photo',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  color: _RideAppColors.txt)),
            const SizedBox(height: 4),
            Text('Choose how to add your photo',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: _RideAppColors.txt3)),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: _imageSourceBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _imageSourceBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: _surfaceDecoration(
            color: _RideAppColors.bg3,
            borderColor: _RideAppColors.amber.withOpacity(0.2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: _RideAppColors.amber),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _RideAppColors.txt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointImages(int cpIndex) {
    final images = _cpImages[cpIndex];
    final hasMinimum = images.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 16, color: _RideAppColors.border),
        Row(
          children: [
            Icon(Icons.camera_alt_rounded,
                size: 16, color: _RideAppColors.amber.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              'Package Photos',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _RideAppColors.txt),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasMinimum
                    ? _RideAppColors.green.withOpacity(0.12)
                    : _RideAppColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${images.length} / 2 min',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasMinimum ? _RideAppColors.green : _RideAppColors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...images.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _cpImages[cpIndex].removeAt(idx)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                      // Image number badge
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${idx + 1}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Add button
              GestureDetector(
                onTap: () => _pickCheckpointImage(cpIndex),
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: _surfaceDecoration(
                    color: _RideAppColors.bg4,
                    borderColor: hasMinimum
                        ? _RideAppColors.amber.withOpacity(0.24)
                        : _RideAppColors.red.withOpacity(0.3),
                  ).copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 22,
                          color: hasMinimum
                              ? _RideAppColors.amber
                              : _RideAppColors.red.withOpacity(0.8)),
                      const SizedBox(height: 4),
                      Text(
                        images.isEmpty ? 'Add Photo' : 'More',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: hasMinimum
                              ? _RideAppColors.amber
                              : _RideAppColors.red.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!hasMinimum)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Please add at least 2 photos of the package',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _RideAppColors.red),
            ),
          ),
      ],
    );
  }

  // ─── Request Body Builder ─────────────────────────────────────────────────

  Map<String, dynamic> _buildRequestBody() {
    final now = DateTime.now().toIso8601String().split('.').first;
    if (_isCourier) {
      return {
        'motorBiker': {'id': widget.driver.motorBikerId},
        'client': {'id': widget.userId},
        'requestType': 'COURIER',
        'requestedTime': now,
        'courierFrom': {
          'name': _currentAddress,
          'latitude': _sLat,
          'longitude': _sLng,
          'driverApprovalRequired': _driverApprovalRequired,
          'driverApproved': false,
          'receiverName': _senderNameController.text.trim(),
          'receiverPhone': _senderPhoneController.text.trim(),
        },
        'checkpoints': _checkpoints.asMap().entries.map((entry) {
          final i = entry.key;
          final cp = entry.value;
          return {
            'name': cp['name'],
            'latitude': cp['lat'],
            'longitude': cp['lng'],
            'order': i + 1,
            'receiverName': i < _cpControllers.length
                ? _cpControllers[i]['receiverName']!.text.trim()
                : '',
            'receiverPhone': i < _cpControllers.length
                ? _cpControllers[i]['receiverPhone']!.text.trim()
                : '',
            'requiresReceiverApproval': i < _cpRequiresApproval.length
                ? _cpRequiresApproval[i]
                : true,
            'packageDescription': i < _cpControllers.length
                ? _cpControllers[i]['packageDesc']!.text.trim()
                : '',
            'packageWeight': i < _cpControllers.length
                ? _cpControllers[i]['packageWeight']!.text.trim()
                : '',
            'specialInstructions': i < _cpControllers.length
                ? _cpControllers[i]['specialInstr']!.text.trim()
                : '',
            'packageImages': i < _cpImages.length
                ? _cpImages[i]
                    .map((f) => base64Encode(f.readAsBytesSync()))
                    .toList()
                : <String>[],
          };
        }).toList(),
        'status': 'PENDING',
        'packageDescription': _packageDescController.text.trim(),
        'packageWeight': _packageWeightController.text.trim(),
        'packageDimensions': _packageDimsController.text.trim(),
        'declaredValue':
            double.tryParse(_declaredValueController.text.trim()) ?? 0.0,
        'specialInstructions': _specialInstrController.text.trim(),
      };
    }
    return {
      'motorBiker': {'id': widget.driver.motorBikerId},
      'client': {'id': widget.userId},
      'requestType': _requestType,
      'requestedTime': now,
      'createdAt': now,
      'updatedAt': now,
      'originLocation': {
        'name': _currentAddress,
        'latitude': _sLat,
        'longitude': _sLng,
      },
      'checkpoints': _checkpoints
          .asMap()
          .entries
          .map((entry) => {
                'name': entry.value['name'],
                'latitude': entry.value['lat'],
                'longitude': entry.value['lng'],
                'order': entry.key + 1,
              })
          .toList(),
      'status': 'PENDING',
    };
  }

  // ─── Step 2 ───────────────────────────────────────────────────────────────

  Widget _buildStep2({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepGuideCard(
            title: 'Final Review',
            description:
                'Double-check the route, confirm the fare, and choose how the client will pay.',
            primaryMeta: _distancePrice == '0.0' ? 'Estimate updates automatically' : 'Estimated $_distancePrice TZS',
            secondaryMeta: _step == _paymentStep ? 'Next: Ready to Confirm' : 'Next: $_nextStepTitle',
            icon: Icons.payments_rounded,
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.04, end: 0),
          const SizedBox(height: 18),
          // Journey summary
          _buildJourneySummary()
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 20),

          _buildSectionLabel('CHOOSE PAYMENT METHOD'),
          const SizedBox(height: 10),

          // Payment options
          ...PaymentMethod.values.asMap().entries.map((entry) {
            final i = entry.key;
            final method = entry.value;
            return _buildPaymentOption(method)
                .animate()
                .fadeIn(duration: 280.ms, delay: (60 * i).ms)
                .slideX(begin: 0.05, end: 0, delay: (60 * i).ms);
          }),

          const SizedBox(height: 16),

          // Selected method detail
          _buildSelectedMethodDetail()
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 24),

          // Back + Confirm row
          Row(
            children: [
              _buildGhostAction(
                onTap: () => _goToStep(_isCourier ? 1 : 0),
                icon: Icons.arrow_back_rounded,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: BlocConsumer<CreateRequestBloc, CreateRequestState>(
                  listener: (ctx, state) {
                    if (state is CreateRequestError) {
                      showErrorAlert(state.message, ctx);
                    }
                    if (state is CreateRequestSuccess) {
                      showSuccessAlert('REQUEST SENT SUCCESSFULLY', ctx);
                      final requestID =
                          state.myRequestsModel.data!.id.toString();
                      final firebaseBody = _lastSubmittedRequestBody ?? _buildRequestBody();
                      _initFirebaseTrip(requestID, firebaseBody);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        ctx.safeGoNamed(myRequests);
                      });
                    }
                  },
                  builder: (ctx, state) {
                    final loading = state is CreateRequestLoading;
                    return _buildPrimaryAction(
                      label: loading ? 'Sending...' : 'Confirm Request',
                      icon: Icons.check_circle_outline_rounded,
                      loading: loading,
                      onTap: loading
                          ? null
                          : () {
                              if (_checkpoints.isEmpty) {
                                showErrorAlert(
                                    'Please add at least one destination',
                                    ctx);
                                return;
                              }
                              final requestBody = _buildRequestBody();
                              _lastSubmittedRequestBody =
                                  Map<String, dynamic>.from(
                                jsonDecode(jsonEncode(requestBody))
                                    as Map<String, dynamic>,
                              );
                              _createRequestBloc.add(HandleCreateRequest(
                                requestBody: requestBody,
                                status: 'PENDING',
                                requestType: _isCourier ? 'COURIER' : 'RIDE',
                              ));
                            },
                    );
                  },
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.12, end: 0),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildJourneySummary() {
    final stops = [
      {'label': 'Pickup', 'address': _currentAddress, 'isPickup': true},
      for (final cp in _checkpoints)
        {'label': 'Checkpoint', 'address': cp['name'] as String, 'isPickup': false},
    ];

    return Container(
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Navy gradient header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: _requestGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.route_rounded,
                      color: _RideAppColors.green, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${stops.length - 1} stop${stops.length - 1 == 1 ? '' : 's'} · $_distanceOriginDestination km',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Service badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    widget.selectedService.isNotEmpty
                        ? widget.selectedService.toUpperCase()
                        : _requestType,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Route timeline body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                for (int i = 0; i < stops.length; i++) ...
                  [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline dot + connector
                        SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? _RideAppColors.green.withOpacity(0.12)
                                      : _requestAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: i == 0
                                        ? _RideAppColors.green.withOpacity(0.3)
                                        : _requestAccent.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  i == 0
                                      ? Icons.my_location_rounded
                                      : Icons.location_on_rounded,
                                  size: 14,
                                  color: i == 0 ? _RideAppColors.green : _requestAccent,
                                ),
                              ),
                              if (i < stops.length - 1)
                                Container(
                                  width: 2,
                                  height: 18,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _RideAppColors.green.withOpacity(0.25),
                                        _requestAccent.withOpacity(0.25),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stops[i]['label'] as String,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _RideAppColors.txt3,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  (stops[i]['address'] as String).isNotEmpty
                                      ? stops[i]['address'] as String
                                      : '—',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _RideAppColors.txt,
                                  ),
                                ),
                                if (i < stops.length - 1)
                                  const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),

          // ── Stats strip ──
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _RideAppColors.bg4,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _RideAppColors.border),
            ),
            child: Row(
              children: [
                _summaryChip(Icons.straighten_rounded,
                    '$_distanceOriginDestination km'),
                const Spacer(),
                _summaryChip(Icons.receipt_long_rounded,
                    '$_distancePrice TZS',
                    isHighlight: true),
                const Spacer(),
                _summaryChip(Icons.person_pin_circle_rounded,
                    widget.driver.displayName.split(' ').first),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text,
      {bool isHighlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isHighlight
                ? _RideAppColors.green.withOpacity(0.15)
                : _requestAccent.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 13,
              color: isHighlight ? _RideAppColors.green : _requestAccent.withOpacity(0.9)),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isHighlight ? _RideAppColors.green : _RideAppColors.txt,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: _surfaceDecoration(
          color: selected ? _requestAccent.withOpacity(0.08) : _RideAppColors.bg3,
          borderColor: selected ? _requestAccent.withOpacity(0.32) : _RideAppColors.border,
        ),
        child: Row(
          children: [
            // Icon container — method color always for visual identity
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? _requestAccent.withOpacity(0.16)
                    : _RideAppColors.bg4,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(method.icon,
                  size: 22,
                  color: selected ? _requestAccent : _RideAppColors.txt3),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _RideAppColors.txt : _RideAppColors.txt2,
                    ),
                  ),
                  Text(
                    method.description,
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: selected
                            ? _RideAppColors.txt3
                            : _RideAppColors.txt3),
                  ),
                ],
              ),
            ),

            // Selected badge or radio ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _requestAccent : Colors.transparent,
                border: Border.all(
                  color: selected ? _requestAccent : _RideAppColors.txt3,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMethodDetail() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(
        gradient: _requestGradient,
        borderColor: _requestAccent.withOpacity(0.28),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _paymentMethod.color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_paymentMethod.icon,
                color: _paymentMethod.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  _paymentMethod.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _RideAppColors.green.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _RideAppColors.green.withOpacity(0.4)),
            ),
            child: Text(
              '$_distancePrice TZS',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _RideAppColors.txt,
              ),
            ),
          ),
        ],
      ),
    );
  }
}