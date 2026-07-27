// In your widget file
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../model/available.driver/available.driver.on.map.model.dart';
import '../../../states/available.driver.location/available_driver_location_bloc.dart';

class AvailableDriversListWidget extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;
  final double distanceThreshold;

  const AvailableDriversListWidget({
    Key? key,
    required this.userLatitude,
    required this.userLongitude,
    this.distanceThreshold = 10.0,
  }) : super(key: key);

  @override
  State<AvailableDriversListWidget> createState() => _AvailableDriversListWidgetState();
}

class _AvailableDriversListWidgetState extends State<AvailableDriversListWidget> {
  final ScrollController scrollController = ScrollController();
  static const Color primaryColor = Color(0xFF00BFA6);

  @override
  void initState() {
    super.initState();
    // Fetch drivers on init
    _fetchDrivers();
  }

  void _fetchDrivers() {
    context.read<AvailableDriverLocationBloc>().add(
          FetchAvailableDriverLocationEvent(
            latitude: widget.userLatitude,
            longitude: widget.userLongitude,
            radiusKm: widget.distanceThreshold,
          ),
        );
  }

  void _refreshDrivers() {
    context.read<AvailableDriverLocationBloc>().add(
          const RefreshAvailableDriversEvent(),
        );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocConsumer<AvailableDriverLocationBloc, AvailableDriverLocationState>(
        listener: (context, state) {
          if (state is AvailableDriverLocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _refreshDrivers,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AvailableDriverLocationLoading) {
            return _buildLoadingState(state);
          }

          if (state is AvailableDriverLocationSuccess) {
            return _buildSuccessState(state);
          }

          if (state is AvailableDriverLocationEmpty) {
            return _buildEmptyState(state);
          }

          if (state is AvailableDriverLocationError) {
            return _buildErrorState(state);
          }

          // Initial state
          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildLoadingState(AvailableDriverLocationLoading state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SpinKitDoubleBounce(
          color: primaryColor,
          size: 50,
        ),
        const SizedBox(height: 20),
        Text(
          state.message ?? 'Finding nearby drivers...',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        if (state.latitude != null && state.longitude != null) ...[
          const SizedBox(height: 8),
          Text(
            'Searching at: ${state.latitude!.toStringAsFixed(4)}, ${state.longitude!.toStringAsFixed(4)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSuccessState(AvailableDriverLocationSuccess state) {
    // Filter drivers within distance threshold
    final nearbyDrivers = state.drivers.where((driver) {
      final distance = calculateDistance(
        widget.userLatitude,
        widget.userLongitude,
        driver.latitude,
        driver.longitude,
      );
      return distance <= widget.distanceThreshold;
    }).toList();

    // Sort by distance
    nearbyDrivers.sort((a, b) {
      final distanceA = calculateDistance(
        widget.userLatitude,
        widget.userLongitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = calculateDistance(
        widget.userLatitude,
        widget.userLongitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    if (nearbyDrivers.isEmpty) {
      return _buildNoDriversNearby(state);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshDrivers();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Column(
        children: [
          // Header with count and last updated
          _buildHeader(state, nearbyDrivers.length),
          
          // Drivers list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nearbyDrivers.length,
              itemBuilder: (context, index) {
                final driver = nearbyDrivers[index];
                final distance = calculateDistance(
                  widget.userLatitude,
                  widget.userLongitude,
                  driver.latitude,
                  driver.longitude,
                );
                return Text(distance.toStringAsFixed(2));

                // return _buildDriverCard(driver, distance, index)
                //     .animate()
                //     .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                //     .slideX(begin: 0.2, end: 0, delay: (50 * index).ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AvailableDriverLocationSuccess state, int nearbyCount) {
    final timeAgo = _getTimeAgo(state.lastUpdated);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nearbyCount ${nearbyCount == 1 ? 'Driver' : 'Drivers'} Nearby',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Updated $timeAgo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: primaryColor,
            onPressed: _refreshDrivers,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriversNearby(AvailableDriverLocationSuccess state) {
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
            'No drivers within ${widget.distanceThreshold}km',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${state.driversCount} drivers but they\'re further away',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshDrivers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
    );
  }

  Widget _buildEmptyState(AvailableDriverLocationEmpty state) {
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
            state.message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshDrivers,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
    );
  }

  Widget _buildErrorState(AvailableDriverLocationError state) {
    return Center(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshDrivers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildInitialState() {
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
            'Ready to find drivers',
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

  // void _onDriverTap(AvailableDriverData driver) {
  //   // Handle driver selection - navigate to details or show bottom sheet
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => _buildDriverDetailsSheet(driver),
  //   );
  // }

  // Widget _buildDriverDetailsSheet(AvailableDriverData driver) {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         // Handle bar
  //         Container(
  //           width: 40,
  //           height: 4,
  //           decoration: BoxDecoration(
  //             color: Colors.grey[300],
  //             borderRadius: BorderRadius.circular(2),
  //           ),
  //         ),
  //         const SizedBox(height: 24),
          
  //         // Driver info
  //         Text(
  //           driver.driverFullName,
  //           style: GoogleFonts.poppins(
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           driver.plateNumber,
  //           style: GoogleFonts.poppins(
  //             fontSize: 16,
  //             color: Colors.grey[600],
  //           ),
  //         ),
  //         const SizedBox(height: 24),
          
  //         // Action buttons
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   // Handle booking
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: primaryColor,
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                 ),
  //                 child: const Text('Book Driver'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}