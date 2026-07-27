// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/create_request_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../api/auth.service.dart';
import '../../../connectivity/check.connectivity.dart';
import '../../../model/active_request_model.dart';
import '../../../model/available.driver/available.driver.on.map.model.dart';
import '../../../model/client_statistics_model.dart';
import '../../../states/available.driver.location/available_driver_location_bloc.dart';
import '../../../states/requests/active_request_bloc.dart';
import '../../../states/requests/update/update_sent_request_status_bloc.dart';
import '../../../utils/google_api_headers.dart';
import 'package:speed_ios/ui/screens/clients/cancel.request/cancel.screen.dart';
import 'request_ride_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class _AppColors {
  // Neutral dark backgrounds
  static const bg = Color(0xFF0B1220);
  static const bg2 = Color(0xFF111827);
  static const bg3 = Color(0xFF1A2234);
  static const bg4 = Color(0xFF202B3F);

  // Brand (Emerald)
  static const accent = Color(0xFF10B981);
  static const accent2 = Color(0xFF059669);
  static const green = Color(0xFF34D399);

  // Status
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);

  // Text
  static const txt = Color(0xFFF8FAFC);
  static const txt2 = Color(0xFFCBD5E1);
  static const txt3 = Color(0xFF94A3B8);

  // Borders
  static const border = Color(0x14FFFFFF);

  // Header/Profile
  static const gradientProfile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF134E4A),
      Color(0xFF059669),
    ],
  );

  // Ride CTA
  static const gradientRide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );

  // Main header
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class Home extends StatefulWidget {
  final String? refreshParam;
  const Home({Key? key, this.refreshParam}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // ── BLoCs ──
  late CreateRequestBloc createRequestBloc;
  late AvailableDriverLocationBloc _availableDriverLocationBloc;
  late ActiveRequestBloc _activeRequestBloc;
  late UpdateSentRequestStatusBloc updateSentRequestStatusBloc;

  // ── Misc ──
  final AuthService _authService = AuthService();
  final NetworkUtils networkUtils = NetworkUtils();
  late AnimationController _refreshController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _db = FirebaseDatabase.instance;

  // ── User state ──
  String? userFullNames;
  String? userPhone;
  int? userId;

  // ── Location ──
  double sLat = 0.0, sLng = 0.0;
  double dLat = 0.0, dLng = 0.0;
  String? _currentAddress;
  String? countryCode = 'rw';
  String? jsonCode;

  // ── Request state ──
  String selectedService = '';
  String locationSelected = '';
  String distanceOriginDestination = '';
  String distancePrice = '0.0';
  String selectedUnitPrice = '850';
  ActiveRequestData? activeRequest;
  bool showRequestCard = false;
  bool _isDriverSheetOpen = false;
  bool _didAutoLoadDrivers = false;
  bool _statsLoading = false;
  String? _statsError;
  ClientStatisticsData? _clientStatistics;
  Timer? _refreshTimer;

  // ── Inline places search ──
  bool _isSearching = false;
  bool _isPickupSearch = false;
  bool _reopenDestinationSheetAfterSearch = false;
  List<Prediction> _suggestions = [];
  bool _searchLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;

  // ── Bottom nav ──
  int _currentNavIndex = 0;

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _getCurrentLocation();
    _loadCountryCode();
    _startPeriodicRefresh();
    _loadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateSentRequestStatusBloc =
        BlocProvider.of<UpdateSentRequestStatusBloc>(context);
    createRequestBloc = BlocProvider.of<CreateRequestBloc>(context);
    _activeRequestBloc = BlocProvider.of<ActiveRequestBloc>(context);
    _availableDriverLocationBloc =
        BlocProvider.of<AvailableDriverLocationBloc>(context);

    if (userId != null) {
      _fetchClientStatistics();
    }
    networkUtils.checkConnectivity(context);
    _fetchAvailableDrivers();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson == null) return;
    final map = jsonDecode(userJson) as Map<String, dynamic>;
    setState(() {
      userFullNames = '${map['fname'] ?? '---'} ${map['lname'] ?? '---'}';
      userPhone = map['phone'];
      userId = map['id'];
    });
    if (userId != null) {
      _fetchClientStatistics();
    }
    _checkActiveRequest();
  }

  Future<void> _fetchClientStatistics() async {
    if (userId == null) return;

    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    final result = await _authService.fetchClientStatistics(userId.toString());
    if (!mounted) return;

    setState(() {
      _statsLoading = false;
      if (result.success && result.data != null) {
        _clientStatistics = result.data;
        _statsError = null;
      } else {
        _clientStatistics = null;
        _statsError = result.message;
      }
    });
  }

  Future<void> _loadCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    jsonCode = prefs.getString('currentCountryCode') ?? 'rw';
    setState(() => countryCode = jsonCode);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _handleRefresh();
    });
  }

  void _handleRefresh() {
    _refreshController.forward(from: 0);
    _fetchAvailableDrivers(
        radiusKm: _isDriverSheetOpen ? 3.0 : 5.0, force: true);
    _checkActiveRequest();
  }

  void _fetchAvailableDrivers({double radiusKm = 5.0, bool force = false}) {
    if (sLat == 0.0 || sLng == 0.0) return;
    if (!force && _didAutoLoadDrivers) return;

    _didAutoLoadDrivers = true;
    _availableDriverLocationBloc.add(
      FetchAvailableDriverLocationEvent(
        latitude: sLat,
        longitude: sLng,
        radiusKm: radiusKm,
      ),
    );
  }

  void _openRequestRideScreen(NearbyDriver driver, {bool closeSheet = false}) {
    if (closeSheet) {
      Navigator.pop(context);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestRideScreen(
          driver: driver,
          selectedService: selectedService,
          currentAddress: _currentAddress ?? '',
          sLat: sLat,
          sLng: sLng,
          userId: userId ?? 0,
          countryCode: countryCode ?? 'rw',
          initialDestinationName:
              locationSelected.isNotEmpty ? locationSelected : null,
          initialDestinationLat: dLat != 0.0 ? dLat : null,
          initialDestinationLng: dLng != 0.0 ? dLng : null,
        ),
      ),
    );
  }

  Future<void> _checkActiveRequest() async {
    if (userId != null) {
      _activeRequestBloc.add(FetchActiveRequestEvent(clientId: userId!));
    }
  }

  Future<void> _initPendingFirebaseTrip(
      String id, String fare, String perKm, String dist) async {
    await _db.ref('active_trips/$id').set({
      'tripId': id,
      'fare': {'totalFare': fare, 'farePerKm': perKm, 'totalDistance': dist},
    });
  }

  String get _userInitials {
    if (userFullNames == null) return 'U';
    return userFullNames!
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  // ─────────────────────────────────────────────
  // LOCATION
  // ─────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _locatePosition(position);
  }

  void _locatePosition(Position pos) async {
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = marks[0];
      setState(() {
        _currentAddress = '${p.street}, ${p.subLocality}, ${p.locality}';
        sLat = pos.latitude;
        sLng = pos.longitude;
      });
      _fetchAvailableDrivers();
    } catch (_) {}
  }

  void _calculateDistance(LatLng dest, LatLng src) {
    final hasRoute = (src.latitude != 0.0 || src.longitude != 0.0) &&
        (dest.latitude != 0.0 || dest.longitude != 0.0);
    if (!hasRoute) {
      setState(() {
        distanceOriginDestination = '';
        distancePrice = '0.0';
      });
      return;
    }

    double meters = Geolocator.distanceBetween(
        src.latitude, src.longitude, dest.latitude, dest.longitude);
    double km = (meters / 1000 * 10).roundToDouble() / 10;
    double price =
        (km * double.parse(selectedUnitPrice) * 10).roundToDouble() / 10;
    setState(() {
      distanceOriginDestination = km.toStringAsFixed(1);
      distancePrice = price.toStringAsFixed(1);
    });
  }

  // ─────────────────────────────────────────────
  // STATUS HELPERS
  // ─────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING_DRIVER':
        return _AppColors.amber;
      case 'APPROVED':
      case 'ASSIGNED':
      case 'ACCEPTED':
        return _AppColors.accent;
      case 'DRIVER_ARRIVING':
        return const Color(0xFFA78BFA);
      case 'IN_PROGRESS':
      case 'ONGOING':
        return _AppColors.green;
      case 'COMPLETED':
        return _AppColors.green;
      case 'REJECTED':
      case 'CANCELLED':
      case 'NO_DRIVER_AVAILABLE':
        return _AppColors.red;
      default:
        return _AppColors.txt3;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Icons.pending_rounded;
      case 'SEARCHING_DRIVER':
        return Icons.search_rounded;
      case 'APPROVED':
        return Icons.check_circle_outline_rounded;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return Icons.person_pin_circle_rounded;
      case 'DRIVER_ARRIVING':
        return Icons.directions_car_rounded;
      case 'IN_PROGRESS':
      case 'ONGOING':
        return Icons.motorcycle_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusMessage(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return 'Your request is pending approval';
      case 'SEARCHING_DRIVER':
        return 'Looking for an available driver...';
      case 'APPROVED':
        return 'Request approved! Finding driver...';
      case 'ASSIGNED':
        return 'Driver has been assigned';
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
      default:
        return 'Status: $s';
    }
  }

  IconData _serviceIcon(String s) {
    switch (s.toUpperCase()) {
      case 'RIDE':
        return Icons.motorcycle_rounded;
      case 'COURIER':
        return Icons.delivery_dining_rounded;
      case 'TAXI_CAB':
        return Icons.local_taxi_rounded;
      case 'TRUCK':
        return Icons.local_shipping_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  LinearGradient _driverGradient(NearbyDriver driver, bool isTop) {
    if (isTop) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD97706), _AppColors.amber],
      );
    }
    if (driver.isDelivery) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F766E), _AppColors.green],
      );
    }
    if (driver.isRide) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_AppColors.accent, _AppColors.accent2],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF475569), Color(0xFF1E293B)],
    );
  }

  Color _driverStatusColor(NearbyDriver driver) {
    if (driver.isOnline) return _AppColors.green;
    if (driver.isBusy) return _AppColors.amber;
    return _AppColors.txt3;
  }

  String _driverStatusLabel(NearbyDriver driver) {
    if (driver.isOnline) return 'Available now';
    if (driver.isBusy) return 'Busy';
    return 'Offline';
  }

  String _statisticsBadgeLabel() {
    if (_statsLoading) return 'Loading your activity';
    if (_statsError != null) return 'Activity unavailable';

    final latest = _clientStatistics?.recentRoutes.isNotEmpty == true
        ? _clientStatistics!.recentRoutes.first
        : null;

    if (latest == null) return 'No recent activity yet';
    return '${_requestTypeLabel(latest.requestType)} • ${_formatRecentRouteTime(latest.createdAt)}';
  }

  String _requestTypeLabel(String requestType) {
    return requestType.toUpperCase() == 'COURIER' ? 'Courier' : 'Ride';
  }

  Color _requestTypeColor(String requestType) {
    return requestType.toUpperCase() == 'COURIER'
        ? _AppColors.amber
        : _AppColors.accent;
  }

  IconData _requestTypeIcon(String requestType) {
    return requestType.toUpperCase() == 'COURIER'
        ? Icons.inventory_2_rounded
        : Icons.motorcycle_rounded;
  }

  String _formatRecentRouteTime(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _driverInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _callDriver([ActiveRequestData? req]) async {
    final data = req ?? activeRequest;
    if (data != null && data.driverContact != 'N/A') {
      final success = await makePhoneCall(data.driverContact);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to place call. Please dial manually.')),
        );
      }
    }
  }

  void _closeInlineSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _isSearching = false;
      _searchLoading = false;
      _suggestions = [];
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  void _openInlineSearch({
    required bool pickup,
    bool reopenDestinationSheet = false,
  }) {
    _searchDebounce?.cancel();
    setState(() {
      _isPickupSearch = pickup;
      _reopenDestinationSheetAfterSearch = reopenDestinationSheet;
      _isSearching = true;
      _searchLoading = false;
      _suggestions = [];
      _searchController.clear();
    });
    Future.microtask(() => _searchFocus.requestFocus());
  }

  Future<void> _queryAutocomplete(String input) async {
    _searchDebounce?.cancel();
    if (input.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
      });
      return;
    }

    setState(() => _searchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final headers = await GoogleApiHeaders.getHeaders();
        final places = GoogleMapsPlaces(
          apiKey: dotenv.get('apiKey'),
          apiHeaders: headers,
        );
        final response = await places.autocomplete(
          input,
          types: [],
          components: [Component(Component.country, countryCode ?? 'rw')],
          language: 'en',
        );

        if (!mounted) return;
        setState(() {
          _suggestions = response.isOkay ? response.predictions : [];
          _searchLoading = false;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _searchLoading = false);
        if (kDebugMode) print('Autocomplete error: $error');
      }
    });
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    final isPickup = _isPickupSearch;
    final reopenSheet = _reopenDestinationSheetAfterSearch;
    _closeInlineSearch();

    try {
      final headers = await GoogleApiHeaders.getHeaders();
      final places = GoogleMapsPlaces(
        apiKey: dotenv.get('apiKey'),
        apiHeaders: headers,
      );
      final detail =
          await places.getDetailsByPlaceId(prediction.placeId ?? '0');
      final geo = detail.result.geometry;
      if (geo == null) return;

      setState(() {
        if (isPickup) {
          sLat = geo.location.lat;
          sLng = geo.location.lng;
          _currentAddress = prediction.description ?? '';
        } else {
          dLat = geo.location.lat;
          dLng = geo.location.lng;
          locationSelected = prediction.description ?? '';
        }
      });

      _calculateDistance(LatLng(dLat, dLng), LatLng(sLat, sLng));

      if (mounted && reopenSheet) {
        Future.microtask(_showDestinationSheet);
      }
    } catch (error) {
      if (kDebugMode) print('Place detail error: $error');
    }
  }

  void _trackRide(ActiveRequestData? req) {
    if (req == null) return;
    context.safeGoNamed(clientDirections, params: {
      'requestId': req.id.toString(),
      'originLocation': req.originLocation.toString(),
      'destinationLocation': req.destinationLocation.toString(),
      'clientNames': '${req.client?.fname} ${req.client?.lname}',
      'clientPhone': '${req.client?.phone}',
      'driverName': '${req.driverName}',
      'driverPhone': '${req.driverPhone}',
    });
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _AppColors.bg,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          _buildSectionHeader('Quick Actions'),
                          _buildQuickActions(),
                          // Active request
                          BlocConsumer<ActiveRequestBloc, ActiveRequestState>(
                            listener: (ctx, state) {
                              if (state is ActiveRequestSuccess) {
                                setState(() {
                                  activeRequest = state.activeRequestModel.data;
                                  showRequestCard = state.hasActiveRequest;
                                });
                              }
                              if (state is NoActiveRequest) {
                                setState(() {
                                  activeRequest = null;
                                  showRequestCard = false;
                                });
                              }
                            },
                            builder: (ctx, state) {
                              if (state is ActiveRequestLoading)
                                return _buildSkeletonCard();
                              if (state is ActiveRequestSuccess &&
                                  state.activeRequestModel.data != null) {
                                return _buildActiveRequestCard(
                                    state.activeRequestModel.data!);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          _buildSearchBar(),
                          _buildSectionHeader('Recent Routes'),
                          _buildRecentRoutes(),
                          _buildSectionHeader('Best Drivers Near You',
                              showAll: true),
                          _buildBestDrivers(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSearching) _buildInlineSearch(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Builder(
              builder: (ctx) => GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: _iconBox(Icons.menu_rounded),
                  )),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _AppColors.txt3)),
                Text('SPEED Client',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.txt)),
              ],
            ),
          ),
          _iconBox(Icons.notifications_outlined, badge: true),
          const SizedBox(width: 8),
          BlocBuilder<ActiveRequestBloc, ActiveRequestState>(
            builder: (_, state) {
              final loading = state is ActiveRequestLoading;
              return GestureDetector(
                onTap: loading ? null : _handleRefresh,
                child: _iconBox(
                  Icons.sync_rounded,
                  loading: loading,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, {bool badge = false, bool loading = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.border),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _AppColors.accent),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: _AppColors.txt2, size: 18),
                if (badge)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _AppColors.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE CARD
  // ─────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        gradient: _AppColors.gradientProfile,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.accent.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _AppColors.accent.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _AppColors.accent2.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar + info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userFullNames ?? '...',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _AppColors.txt)),
                          const SizedBox(height: 2),
                          Text(userPhone ?? '',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _AppColors.txt2.withOpacity(0.8))),
                          const SizedBox(height: 6),
                          _buildActivityBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatChip(
                      'Total Rides',
                      '${_clientStatistics?.rideRequestCount ?? 0}',
                      _statsLoading ? 'loading' : 'recorded',
                      _AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Courier',
                      '${_clientStatistics?.courierRequestCount ?? 0}',
                      _statsLoading ? 'loading' : 'sent',
                      _AppColors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Recent Routes',
                      '${_clientStatistics?.recentRoutes.length ?? 0}',
                      _statsLoading ? 'loading' : 'saved',
                      _AppColors.amber,
                    ),
                  ],
                ),
                if (_statsError != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _fetchClientStatistics,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _AppColors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _AppColors.red.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.refresh_rounded,
                              size: 15, color: _AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statsError!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _AppColors.txt2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _AppColors.gradientRide,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(_userInitials,
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildActivityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _AppColors.accent.withOpacity(0.2),
          _AppColors.accent2.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_rounded, size: 12, color: _AppColors.accent),
          const SizedBox(width: 4),
          Text(_statisticsBadgeLabel(),
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.accent)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.txt3,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1)),
            const SizedBox(height: 2),
            Text(sub,
                style:
                    GoogleFonts.dmSans(fontSize: 10, color: _AppColors.txt2)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? _AppColors.txt3),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: iconColor ?? _AppColors.txt2)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool showAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.txt)),
          const Spacer(),
          if (showAll)
            GestureDetector(
              onTap: () => _availableDriverLocationBloc.add(
                  FetchAvailableDriverLocationEvent(
                      latitude: sLat, longitude: sLng, radiusKm: 5.0)),
              child: Text('See all',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.accent)),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // QUICK ACTIONS
  // ─────────────────────────────────────────────
  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Bodaboda',
      'service': 'Ride',
      'icon': Icons.motorcycle_rounded,
      'gradient': _AppColors.gradientRide
    },
    {
      'title': 'Taxi',
      'service': 'TAXI_CAB',
      'icon': Icons.local_taxi_rounded,
      'gradient': _AppColors.gradientRide
    },
    {
      'title': 'Send Package',
      'service': 'COURIER',
      'icon': Icons.delivery_dining_rounded,
      'gradient': _AppColors.gradientRide
    },
    {
      'title': 'Private',
      'service': 'PRIVATE',
      'icon': Icons.local_taxi_rounded,
      'gradient': _AppColors.gradientRide
    },
  ];

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_services.length, (i) {
          final s = _services[i];
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: i < _services.length - 1 ? 10 : 0),
              child: _buildQaButton(
                title: s['title'] as String,
                service: s['service'] as String,
                icon: s['icon'] as IconData,
                gradient: s['gradient'] as LinearGradient,
                index: i,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQaButton({
    required String title,
    required String service,
    required IconData icon,
    required LinearGradient gradient,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _selectService(service),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _AppColors.border),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 26),
          ),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: _AppColors.txt2,
                  fontWeight: FontWeight.w500,
                  height: 1.3)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (80 * index).ms).scale(
        begin: const Offset(0.8, 0.8),
        delay: (80 * index).ms,
        curve: Curves.easeOutBack);
  }

  void _selectService(String service, {bool closeSheet = false}) {
    if (closeSheet && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() => selectedService = service);

    if (sLat == 0.0 || sLng == 0.0) {
      _getCurrentLocation().then((_) {
        if (!mounted) return;
        if (sLat != 0.0 && sLng != 0.0) {
          _showDriversSheet();
        }
      });
      return;
    }

    _showDriversSheet();
  }

  // ─────────────────────────────────────────────
  // ACTIVE REQUEST CARD
  // ─────────────────────────────────────────────
  Widget _buildActiveRequestCard(ActiveRequestData req) {
    final status = req.status ?? 'UNKNOWN';
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final message = _statusMessage(status);
    final isActive = req.isActive;
    final hasDriver = req.hasDriver;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Request',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: _AppColors.txt3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          Text(status.replaceAll('_', ' '),
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ),
                    ),
                    if (isActive) _buildActiveDot(),
                  ],
                ),
                const SizedBox(height: 12),
                // Status message
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(message,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _AppColors.txt2)),
                      ),
                    ],
                  ),
                ),
                // Route
                if (req.originLocation != null ||
                    req.destinationLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildRouteRow(req.originLocation, req.destinationLocation),
                ],
                // Driver row
                if (hasDriver &&
                    [
                      'ASSIGNED',
                      'ACCEPTED',
                      'DRIVER_ARRIVING',
                      'IN_PROGRESS',
                      'ONGOING'
                    ].contains(status.toUpperCase())) ...[
                  const SizedBox(height: 12),
                  _buildDriverRow(req),
                ],
                // Fare chips
                if (req.distanceKm != null || req.estimatedFare != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (req.distanceKm != null)
                        _buildFareChip(
                            Icons.straighten_rounded,
                            '${req.distanceKm!.toStringAsFixed(1)} km',
                            _AppColors.accent),
                      if (req.distanceKm != null && req.estimatedFare != null)
                        const SizedBox(width: 8),
                      if (req.estimatedFare != null)
                        _buildFareChip(
                            Icons.payments_outlined,
                            '${req.estimatedFare!.toStringAsFixed(0)} Tsh',
                            _AppColors.green),
                    ],
                  ),
                ],
                // Action buttons
                if (isActive) ...[
                  const SizedBox(height: 14),
                  _buildActionButtons(status, color, req),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildActiveDot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _AppColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _AppColors.green,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 800.ms)
              .then()
              .fadeOut(duration: 800.ms),
          const SizedBox(width: 5),
          Text('Active',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.green)),
        ],
      ),
    );
  }

  Widget _buildRouteRow(String? origin, String? destination) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          if (origin != null)
            _routeStop(Icons.circle, 8, _AppColors.green, origin),
          if (origin != null && destination != null)
            Padding(
              padding: const EdgeInsets.only(left: 3.5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    width: 1.5,
                    height: 14,
                    color: _AppColors.txt3.withOpacity(0.3)),
              ),
            ),
          if (destination != null)
            _routeStop(
                Icons.location_on_rounded, 14, _AppColors.red, destination),
        ],
      ),
    );
  }

  Widget _routeStop(IconData icon, double size, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: size, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.txt2)),
        ),
      ],
    );
  }

  Widget _buildDriverRow(ActiveRequestData req) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.accent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_rounded,
                color: _AppColors.accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    req.fullDriverName.isNotEmpty
                        ? req.fullDriverName
                        : 'Driver Assigned',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.accent)),
                if (req.driverContact != 'N/A')
                  Text(req.driverContact,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _AppColors.txt3)),
              ],
            ),
          ),
          if (req.motorBiker?.plateNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(req.motorBiker!.plateNumber!,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.accent)),
            ),
        ],
      ),
    );
  }

  Widget _buildFareChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      String status, Color color, ActiveRequestData req) {
    Widget btn(IconData icon, String label, Color c, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: c),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: c)),
              ],
            ),
          ),
        ),
      );
    }

    final cancel = btn(Icons.cancel_outlined, 'Cancel', _AppColors.red,
        () => _showCancelSheet(req.id!.toInt()));
    final track = btn(Icons.location_searching_rounded, 'Track',
        _AppColors.accent, () => _trackRide(req));
    final call = btn(
        Icons.call_rounded, 'Call', _AppColors.green, () => _callDriver(req));

    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SEARCHING_DRIVER':
        return Row(children: [
          cancel,
          const SizedBox(width: 8),
          Expanded(
              child: GestureDetector(
            onTap: _handleRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.refresh_rounded, size: 14, color: color),
                const SizedBox(width: 4),
                Text('Refresh',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ]),
            ),
          ))
        ]);
      case 'APPROVED':
        return Row(children: [cancel, const SizedBox(width: 8), track]);
      case 'ASSIGNED':
      case 'ACCEPTED':
      case 'DRIVER_ARRIVING':
        return Row(children: [
          cancel,
          const SizedBox(width: 6),
          call,
          const SizedBox(width: 6),
          track
        ]);
      case 'IN_PROGRESS':
      case 'ONGOING':
        return Row(children: [call, const SizedBox(width: 8), track]);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Where are you going?',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.txt)),
          ),
          GestureDetector(
            onTap: () => _searchDestination(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _AppColors.bg3,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _AppColors.accent.withOpacity(0.35), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: _AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locationSelected.isNotEmpty
                          ? locationSelected
                          : 'Search your destination',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: locationSelected.isNotEmpty
                              ? _AppColors.txt
                              : _AppColors.txt3),
                    ),
                  ),
                  Icon(Icons.schedule_rounded,
                      color: _AppColors.txt3, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoutes() {
    if (_statsLoading && _clientStatistics == null) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _AppColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.border),
            ),
            child: Column(
              children: [
                _shimmerBox(12, double.infinity),
                const SizedBox(height: 8),
                _shimmerBox(10, 180),
              ],
            ),
          ),
        ),
      );
    }

    final routes =
        _clientStatistics?.recentRoutes ?? const <ClientRecentRoute>[];

    if (routes.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: _AppColors.txt3, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _statsError ?? 'No recent routes yet',
                style: GoogleFonts.dmSans(fontSize: 13, color: _AppColors.txt3),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: routes.map((route) {
        final color = _requestTypeColor(route.requestType);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _AppColors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_requestTypeIcon(route.requestType),
                    size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.originLocation} → ${route.destinationLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.txt,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_requestTypeLabel(route.requestType)} • ${_formatRecentRouteTime(route.createdAt)}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _AppColors.txt3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _AppColors.txt3, size: 16),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // BEST DRIVERS
  // ─────────────────────────────────────────────
  Widget _buildBestDrivers() {
    return SizedBox(
      height: 200,
      child: BlocBuilder<AvailableDriverLocationBloc,
          AvailableDriverLocationState>(
        builder: (_, state) {
          if (state is AvailableDriverLocationLoading) {
            return const Center(
                child: SpinKitDoubleBounce(color: _AppColors.accent, size: 36));
          }
          if (state is AvailableDriverLocationSuccess) {
            final drivers = state.drivers
                .where((d) => d.distanceKm <= 5.0)
                .toList()
              ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

            if (drivers.isEmpty) return _buildNoDriversState();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: drivers.length,
              itemBuilder: (ctx, i) => (i == 0
                      ? _buildBestDriverCard(drivers[i])
                      : _buildNearbyDriverCard(drivers[i]))
                  .animate()
                  .fadeIn(duration: 350.ms, delay: (60 * i).ms)
                  .slideX(begin: 0.2, end: 0, delay: (60 * i).ms),
            );
          }
          return _buildNoDriversState();
        },
      ),
    );
  }

  Widget _buildBestDriverCard(NearbyDriver driver) {
    final initials = driver.displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final gradient = _driverGradient(driver, true);
    final statusColor = _driverStatusColor(driver);

    return Container(
      width: 214,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _AppColors.accent.withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _AppColors.accent.withOpacity(0.2)),
            ),
            child: Text(
              'Best match',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.txt,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _driverStatusLabel(driver),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.txt2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  driver.vehicleType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.txt3,
                  ),
                ),
              ),
              if (driver.hasRating) ...[
                const SizedBox(width: 8),
                Icon(Icons.star_rounded, size: 14, color: _AppColors.amber),
                const SizedBox(width: 4),
                Text(
                  driver.formattedRating,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.txt2,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _openRequestRideScreen(driver),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: _AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Request',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _AppColors.accent)),
                        const SizedBox(
                          width: 3,
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 12, color: _AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async{
                    final success = await makePhoneCall(driver.motorBikerPhone);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to place call. Please dial manually.')),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _AppColors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: _AppColors.amber.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Call',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _AppColors.amber)),
                        const SizedBox(width: 3),
                        const Icon(Icons.call_rounded,
                            size: 12, color: _AppColors.amber),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyDriverCard(NearbyDriver driver) {
    final initials = driver.displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final gradient = _driverGradient(driver, false);
    final statusColor = _driverStatusColor(driver);
    final locationName = driver.currentLocationName.trim().isEmpty
        ? 'Nearby pickup zone'
        : driver.currentLocationName.trim();

    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.txt,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.vehicleType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.txt3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _driverInfoChip(
                icon: Icons.location_on_rounded,
                label: driver.formattedDistance,
                color: _AppColors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    _driverStatusLabel(driver),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openRequestRideScreen(driver),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View driver',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.txt,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: _AppColors.txt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriversState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 36, color: _AppColors.txt3),
          const SizedBox(height: 8),
          Text('No drivers nearby',
              style: GoogleFonts.dmSans(fontSize: 14, color: _AppColors.txt3)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (sLat != 0.0) {
                _availableDriverLocationBloc.add(
                    FetchAvailableDriverLocationEvent(
                        latitude: sLat, longitude: sLng, radiusKm: 5.0));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
              ),
              child: Text('Refresh',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.accent)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SKELETON LOADING
  // ─────────────────────────────────────────────
  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _shimmerBox(36, 36, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(12, 80),
                    const SizedBox(height: 6),
                    _shimmerBox(16, 140),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _shimmerBox(40, double.infinity, radius: 10),
        ],
      ),
    );
  }

  Widget _shimmerBox(double h, double w, {double radius = 6}) {
    return Container(
      height: h,
      width: w == double.infinity ? null : w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.15));
  }

  // ─────────────────────────────────────────────
  // BOTTOM NAV
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.bg.withOpacity(0.95),
        border: Border(top: BorderSide(color: _AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', 0),
              _navItem(Icons.motorcycle_rounded, 'My Rides', 1),
              _navBookButton(),
              _navItem(Icons.grid_view_rounded, 'Services', 3),
              _navItem(Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          _showServicesSheet();
          return;
        }
        if (index == 4) {
          _scaffoldKey.currentState?.openDrawer();
          return;
        }

        setState(() => _currentNavIndex = index);
        if (index == 1) context.safeGoNamed(myRequests);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: active ? _AppColors.accent : _AppColors.txt3, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: active ? _AppColors.accent : _AppColors.txt3,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _navBookButton() {
    return GestureDetector(
      onTap: _showDestinationSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _AppColors.gradientRide,
              boxShadow: [
                BoxShadow(
                  color: _AppColors.accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 3),
          Text('Request Ride',
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.accent)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SERVICES SHEET
  // ─────────────────────────────────────────────
  void _showServicesSheet() {
    setState(() => _currentNavIndex = 3);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _AppColors.bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _AppColors.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _AppColors.txt3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'All Services',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.txt,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a service to see available drivers near you.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _AppColors.txt3,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (_, index) {
                    final service = _services[index];
                    final isSelected = selectedService == service['service'];
                    return GestureDetector(
                      onTap: () => _selectService(
                        service['service'] as String,
                        closeSheet: true,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: service['gradient'] as LinearGradient,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white.withOpacity(0.12),
                            width: isSelected ? 1.6 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                service['icon'] as IconData,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              service['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View nearby drivers',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _currentNavIndex = 0);
    });
  }

  // ─────────────────────────────────────────────
  // DESTINATION SHEET
  // ─────────────────────────────────────────────
  void _showDestinationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: _AppColors.bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _AppColors.txt3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Book a Ride',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.txt)),
              const SizedBox(height: 4),
              Text('Select your destination then choose a service',
                  style:
                      GoogleFonts.dmSans(fontSize: 13, color: _AppColors.txt3)),
              const SizedBox(height: 20),
              // Origin
              _buildSheetField(
                icon: Icons.circle,
                iconColor: _AppColors.green,
                hint: _currentAddress ?? 'Your pickup location',
                onTap: () {
                  Navigator.pop(context);
                  _searchOrigin();
                },
              ),
              const SizedBox(height: 10),
              _buildSheetField(
                icon: Icons.location_on_rounded,
                iconColor: _AppColors.red,
                hint: locationSelected.isNotEmpty
                    ? locationSelected
                    : 'Where to?',
                onTap: () {
                  Navigator.pop(context);
                  _searchDestination();
                },
              ),
              if (locationSelected.isNotEmpty &&
                  distanceOriginDestination.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPriceRow(),
              ],
              const SizedBox(height: 20),
              Text('Choose service',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.txt)),
              const SizedBox(height: 12),
              Row(
                children: _services.map((s) {
                  final selected = selectedService == s['service'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(
                              () => selectedService = s['service'] as String);
                          Navigator.pop(context);
                          _showDriversSheet();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? _AppColors.accent.withOpacity(0.15)
                                : _AppColors.bg3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _AppColors.accent
                                  : _AppColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(s['icon'] as IconData,
                                  size: 22,
                                  color: selected
                                      ? _AppColors.accent
                                      : _AppColors.txt3),
                              const SizedBox(height: 4),
                              Text(s['title'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? _AppColors.accent
                                          : _AppColors.txt3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 10, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(hint,
                  style:
                      GoogleFonts.dmSans(fontSize: 13, color: _AppColors.txt2)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: _AppColors.txt3),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _priceItem(Icons.straighten_rounded, 'Distance',
              '$distanceOriginDestination km', _AppColors.accent),
          Container(width: 1, height: 36, color: _AppColors.border),
          _priceItem(Icons.payments_outlined, 'Rate/km', selectedUnitPrice,
              _AppColors.amber),
          Container(width: 1, height: 36, color: _AppColors.border),
          _priceItem(Icons.account_balance_wallet_rounded, 'Total',
              distancePrice, _AppColors.green),
        ],
      ),
    );
  }

  Widget _buildInlineSearch() {
    final hint =
        _isPickupSearch ? 'Where are you now?' : 'Search destination...';

    return GestureDetector(
      onTap: _closeInlineSearch,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: _AppColors.bg2,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _AppColors.border),
                boxShadow: const [
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
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _AppColors.txt3,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_isPickupSearch
                                    ? _AppColors.green
                                    : _AppColors.accent)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isPickupSearch
                                ? Icons.my_location_rounded
                                : Icons.location_on_rounded,
                            color: _isPickupSearch
                                ? _AppColors.green
                                : _AppColors.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPickupSearch
                                ? 'Change Pickup'
                                : 'Search Destination',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.txt,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeInlineSearch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _AppColors.bg3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: _AppColors.txt2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _AppColors.bg3,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (_isPickupSearch
                                  ? _AppColors.green
                                  : _AppColors.accent)
                              .withOpacity(0.25),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (value) {
                          setState(() {});
                          _queryAutocomplete(value);
                        },
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _AppColors.txt),
                        cursorColor: _isPickupSearch
                            ? _AppColors.green
                            : _AppColors.accent,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _AppColors.txt3,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: (_isPickupSearch
                                    ? _AppColors.green
                                    : _AppColors.accent)
                                .withOpacity(0.7),
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
                                    color: _AppColors.txt3,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: _searchLoading
                        ? _buildSearchShimmer()
                        : _suggestions.isEmpty
                            ? _buildSearchEmpty()
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: _AppColors.border,
                                ),
                                itemBuilder: (context, index) {
                                  final prediction = _suggestions[index];
                                  final main = prediction
                                          .structuredFormatting?.mainText ??
                                      prediction.description ??
                                      '';
                                  final secondary = prediction
                                          .structuredFormatting
                                          ?.secondaryText ??
                                      '';
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _onPlaceSelected(prediction),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: (_isPickupSearch
                                                      ? _AppColors.green
                                                      : _AppColors.accent)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.place_rounded,
                                              color: _isPickupSearch
                                                  ? _AppColors.green
                                                  : _AppColors.accent,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  main,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _AppColors.txt,
                                                  ),
                                                ),
                                                if (secondary.isNotEmpty)
                                                  Text(
                                                    secondary,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color: _AppColors.txt3,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.north_west_rounded,
                                            size: 14,
                                            color: _AppColors.txt3,
                                          ),
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
          (index) => Padding(
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
            color: _AppColors.txt3,
          ),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'No results found' : 'Start typing to search',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _AppColors.txt3,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9,
                color: _AppColors.txt3,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // DRIVERS BOTTOM SHEET
  // ─────────────────────────────────────────────
  void _showDriversSheet() {
    _isDriverSheetOpen = true;
    if (sLat != 0.0 && sLng != 0.0) {
      _fetchAvailableDrivers(radiusKm: 3.0, force: true);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: _AppColors.bg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _AppColors.txt3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_serviceIcon(selectedService),
                          color: _AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Drivers',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _AppColors.txt)),
                          Text('$selectedService service',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: _AppColors.txt3)),
                        ],
                      ),
                    ),
                    BlocBuilder<AvailableDriverLocationBloc,
                        AvailableDriverLocationState>(
                      builder: (_, state) {
                        final loading = state is AvailableDriverLocationLoading;
                        return GestureDetector(
                          onTap: loading
                              ? null
                              : () {
                                  if (sLat != 0.0) {
                                    _fetchAvailableDrivers(
                                        radiusKm: 3.0, force: true);
                                  }
                                },
                          child:
                              _iconBox(Icons.refresh_rounded, loading: loading),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: BlocBuilder<AvailableDriverLocationBloc,
                    AvailableDriverLocationState>(
                  builder: (ctx, state) {
                    if (state is AvailableDriverLocationLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SpinKitDoubleBounce(
                                color: _AppColors.accent, size: 40),
                            const SizedBox(height: 16),
                            Text('Finding nearby drivers...',
                                style: GoogleFonts.dmSans(
                                    fontSize: 14, color: _AppColors.txt2)),
                          ],
                        ),
                      );
                    }
                    if (state is AvailableDriverLocationSuccess) {
                      final list = state.drivers
                          .where((d) => d.distanceKm <= 3.0)
                          .toList()
                        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                      if (list.isEmpty) {
                        return _buildSheetEmptyState(state);
                      }
                      return ListView.builder(
                        controller: sc,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            _buildSheetDriverCard(list[i], i == 0, i),
                      );
                    }
                    if (state is AvailableDriverLocationError) {
                      return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: _AppColors.red),
                              const SizedBox(height: 12),
                              Text(state.message,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, color: _AppColors.txt2),
                                  textAlign: TextAlign.center),
                            ]),
                      );
                    }
                    return Center(
                      child: Text('Tap refresh to find drivers',
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: _AppColors.txt3)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _isDriverSheetOpen = false);
  }

  Widget _buildSheetEmptyState(AvailableDriverLocationSuccess state) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search_off_rounded, size: 56, color: _AppColors.txt3),
        const SizedBox(height: 16),
        Text('No drivers within 3km',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _AppColors.txt2)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () =>
              _availableDriverLocationBloc.add(const ExpandSearchRadiusEvent()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_rounded,
                  color: _AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text('Expand Search',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.accent)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSheetDriverCard(NearbyDriver driver, bool isTop, int index) {
    final initials = driver.displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final gradient = _driverGradient(driver, isTop);
    final statusColor = _driverStatusColor(driver);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.bg3,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isTop ? _AppColors.amber.withOpacity(0.3) : _AppColors.border,
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                alignment: Alignment.center,
                child: Text(initials,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.displayName,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.txt)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _driverStatusLabel(driver),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              // Call button
              GestureDetector(
                onTap: () async {
                  final success = await makePhoneCall(driver.motorBikerPhone);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Unable to place call. Please dial manually.')),
                    );
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _AppColors.green.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: _AppColors.green, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _driverInfoChip(
                icon: Icons.phone_rounded,
                label: driver.motorBikerPhone,
                color: _AppColors.accent,
              ),
              _driverInfoChip(
                icon: Icons.location_on_rounded,
                label: '${driver.formattedDistance} away',
                color: _AppColors.green,
              ),
              if (driver.hasRating)
                _driverInfoChip(
                  icon: Icons.star_rounded,
                  label: driver.formattedRating,
                  color: _AppColors.amber,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final success = await makePhoneCall(driver.motorBikerPhone);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Unable to place call. Please dial manually.')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _AppColors.green.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call_rounded,
                            size: 14, color: _AppColors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Call Driver',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openRequestRideScreen(driver, closeSheet: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.send_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Request',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: (60 * index).ms)
        .slideX(begin: 0.1, end: 0, delay: (60 * index).ms);
  }

  // ─────────────────────────────────────────────
  // SEARCH HELPERS
  // ─────────────────────────────────────────────
  void _searchDestination() async {
    _openInlineSearch(
      pickup: false,
      reopenDestinationSheet: true,
    );
  }

  void _searchOrigin() async {
    _openInlineSearch(
      pickup: true,
      reopenDestinationSheet: true,
    );
  }

  /// Attempts to place a call using flutter_phone_direct_caller first,
  /// then falls back to url_launcher's tel: scheme if that fails.
  /// Returns true if either method succeeded in initiating a call.
  Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanedNumber = _cleanNumber(phoneNumber);

    if (cleanedNumber.isEmpty) {
      debugPrint(
          'makePhoneCall: empty/invalid number after cleaning: $phoneNumber');
      return false;
    }

    // Attempt 1: flutter_phone_direct_caller
    try {
      final bool? result =
          await FlutterPhoneDirectCaller.callNumber(cleanedNumber);
      if (result == true) {
        debugPrint('makePhoneCall: succeeded via flutter_phone_direct_caller');
        return true;
      }
      debugPrint(
          'makePhoneCall: flutter_phone_direct_caller returned $result, falling back');
    } catch (e) {
      debugPrint(
          'makePhoneCall: flutter_phone_direct_caller threw $e, falling back');
    }

    // Attempt 2: url_launcher fallback (opens native dialer)
    try {
      final Uri telUri = Uri(scheme: 'tel', path: cleanedNumber);
      if (await canLaunchUrl(telUri)) {
        final launched = await launchUrl(telUri);
        debugPrint('makePhoneCall: url_launcher launched=$launched');
        return launched;
      } else {
        debugPrint('makePhoneCall: canLaunchUrl returned false for $telUri');
      }
    } catch (e) {
      debugPrint('makePhoneCall: url_launcher threw $e');
    }

    return false;
  }

  /// Strips whitespace, dashes, parens — keeps digits and a leading +.
  String _cleanNumber(String raw) {
    final trimmed = raw.trim();
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (char == '+' && i == 0) {
        buffer.write(char);
      } else if (RegExp(r'\d').hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  // ─────────────────────────────────────────────
  // CANCEL SHEET
  // ─────────────────────────────────────────────
  void _showCancelSheet(int requestId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CancelRequestBottomSheet(
          onConfirmCancel: (reason) {
            _showFinalConfirmation(requestId, reason);
          },
        ),
      ),
    );
  }

  void _showFinalConfirmation(int requestId, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _AppColors.bg2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _AppColors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _AppColors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Confirm Cancellation',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.txt)),
              const SizedBox(height: 8),
              Text('Are you sure you want to cancel this request?',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.dmSans(fontSize: 13, color: _AppColors.txt2)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _AppColors.bg3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason:',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.txt3)),
                    const SizedBox(height: 4),
                    Text(reason,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _AppColors.txt)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _AppColors.bg3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text('Go Back',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.txt2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<UpdateSentRequestStatusBloc,
                      UpdateSentRequestStatusState>(
                    builder: (_, state) {
                      final loading = state is UpdateSentRequestStatusLaoding;
                      return GestureDetector(
                        onTap: loading
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                updateSentRequestStatusBloc
                                    .add(HandleUpdateStatus(
                                  requestId: requestId.toString(),
                                  status: 'CANCELLED',
                                  cancellationReason: reason,
                                ));
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_AppColors.red, const Color(0xFFE53935)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _AppColors.red.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Yes, Cancel',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DRAWER
  // ─────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF022C22), // Emerald 950
              Color(0xFF064E3B), // Emerald 900
              Color(0xFF047857), // Emerald 700
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        ),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(_userInitials,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userFullNames ?? '---',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (userPhone != null)
                            Text(userPhone!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.15, end: 0),
              Divider(
                  color: Colors.white.withOpacity(0.1),
                  indent: 20,
                  endIndent: 20),
              const SizedBox(height: 8),
              _drawerItem(
                  Icons.home_rounded, 'Home', () => Navigator.pop(context), 80),
              _drawerItem(Icons.receipt_long_rounded, 'My Requests', () {
                Navigator.pop(context);
                context.safeGoNamed(myRequests);
              }, 140),
              _drawerItem(Icons.history_rounded, 'Ride History', () {
                Navigator.pop(context);
                context.safeGoNamed(myRequests);
              }, 200),
              _drawerItem(Icons.person_rounded, 'Add Referral Code', () {
                Navigator.pop(context);
                context.safeGoNamed(
                  addReferralCode,
                  params: {'clientId': userId.toString()},
                );
              }, 260),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('SPEED Client v1.0',
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: Colors.white24)),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent, size: 20),
                  ),
                  title: Text('Logout',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Text('Sign out of your account',
                      style: GoogleFonts.dmSans(
                          color: Colors.white38, fontSize: 11)),
                  onTap: () => _showLogoutDialog(),
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 300.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String label, VoidCallback onTap, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6EE7B7),
            size: 20,
          ),
        ),
        title: Text(label,
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        onTap: onTap,
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, delay: delay.ms)
        .slideX(begin: -0.12, end: 0, delay: delay.ms);
  }

  Future<void> _showLogoutDialog() async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _AppColors.bg2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Logout',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.txt)),
            const SizedBox(height: 8),
            Text('Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.dmSans(fontSize: 13, color: _AppColors.txt2)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _AppColors.bg3,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text('Cancel',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.txt2)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Colors.redAccent, Color(0xFFE53935)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Yes, Logout',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      context.safeGoNamed(splash);
    }
  }
}

// ─────────────────────────────────────────────
// ROUTE STOP HELPERS (kept for compatibility)
// ─────────────────────────────────────────────
enum _StopType { origin, checkpoint, destination }

class _RouteStop {
  final String name;
  final _StopType type;
  const _RouteStop({required this.name, required this.type});
}
