import 'dart:async';
import 'dart:convert';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/fetch/received_sent_requests_bloc.dart';
import 'package:speed_ios/states/requests/update/update_sent_request_status_bloc.dart';
import 'package:speed_ios/ui/screens/clients/cancel.request/cancel.screen.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../model/received.sent.requests.model.dart';
import '../../../utils/notifiers.dart';

class _RequestsColors {
  // Backgrounds
  static const bg = Color(0xFF0B1220);
  static const bg2 = Color(0xFF111827);
  static const bg3 = Color(0xFF1A2234);
  static const bg4 = Color(0xFF202B3F);

  // Surfaces
  static const surface = Color(0xFF172033);
  static const surface2 = Color(0xFF1F2A40);

  // Brand Colors
  static const accent = Color(0xFF10B981);
  static const accent2 = Color(0xFF059669);

  // Status
  static const green = Color(0xFF34D399);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);

  // Text
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFFCBD5E1);
  static const textSoft = Color(0xFF94A3B8);

  // Border
  static const border = Color(0x14FFFFFF);

  // Page Background
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B1220),
      Color(0xFF111827),
      Color(0xFF0F172A),
    ],
  );

  // Hero/Header
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF134E4A),
      Color(0xFF059669),
    ],
  );
}
class RequestsScreen extends StatefulWidget {
  final String? refreshParam;

  const RequestsScreen({Key? key, this.refreshParam}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late ReceivedSentRequestsBloc receivedSentRequestsBloc;
  late AnimationController _refreshController;
  int? userId;
  UpdateSentRequestStatusBloc updateSentRequestStatusBloc =
      UpdateSentRequestStatusBloc(
          UpdateSentRequestStatusInitial(), AuthService());

  @override
  void initState() {
    super.initState();
    receivedSentRequestsBloc =
        BlocProvider.of<ReceivedSentRequestsBloc>(context);
    updateSentRequestStatusBloc =
        BlocProvider.of<UpdateSentRequestStatusBloc>(context);
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadUserRequests();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

Color statusStr(String status) {
  switch (status) {
    case 'APPROVED':
      return const Color(0xFF1B8A4C); // deep green
    case 'REJECTED':
      return const Color(0xFFD32F2F); // deep red
    case 'PENDING':
      return const Color(0xFFF57C00); // deep amber
    case 'CANCELLED':
      return const Color(0xFF546E7A); // blue-grey
    case 'ONGOING':
      return const Color(0xFF1565C0); // deep blue
    
    case 'COMPLETED':
      return const Color(0xFF00796B); // teal
    case 'DRIVER_ARRIVING':
      return const Color(0xFF6A1B9A); // deep purple
    default:
      return const Color(0xFF424242); // dark grey
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'APPROVED':
      return Icons.check_circle_rounded;
    case 'REJECTED':
      return Icons.cancel_rounded;
    case 'PENDING':
      return Icons.hourglass_top_rounded;
    case 'CANCELLED':
      return Icons.block_rounded;
    case 'ONGOING':
      return Icons.local_taxi_rounded;
    case 'COMPLETED':
      return Icons.task_alt_rounded;
    case 'DRIVER_ARRIVING':
      return Icons.directions_bike_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

// Improved method to load requests
  Future<void> _loadUserRequests() async {
    try {
      final SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      final String? userJson = sharedPreferences.getString("currentUser");

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final int? userId = userMap['id'] as int?;

        if (userId != null) {
          if (mounted) {
            setState(() {
              this.userId = userId;
            });
          }
          receivedSentRequestsBloc.add(
            HandleFetchRequests(userId: userId.toString()),
          );
        } else {
          if (kDebugMode) {
            print('User ID is null in stored user data');
          }
        }
      } else {
        if (kDebugMode) {
          print('User info not found in SharedPreferences');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user requests: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  void _handleRefresh() {
    _refreshController.forward(from: 0);
    _loadUserRequests();
  }

  void showRequestDetails(BuildContext context, singleRequest) {
    // Safe null check for cancellationReason
    String? cancellationReason;
    try {
      cancellationReason = singleRequest.cancellationReason?.toString();
    } catch (e) {
      cancellationReason = null;
    }

    final bool hasReason = (singleRequest.status == 'CANCELLED' ||
            singleRequest.status == 'REJECTED') &&
        cancellationReason != null &&
        cancellationReason.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_RequestsColors.bg3, _RequestsColors.bg2],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: Offset(0, -5),
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
                      color: _RequestsColors.textSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (your existing code)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Request Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      statusStr(singleRequest.status.toString())
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      statusIcon(
                                          singleRequest.status.toString()),
                                      size: 14,
                                      color: statusStr(
                                          singleRequest.status.toString()),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      singleRequest.status.toString(),
                                      style: GoogleFonts.poppins(
                                        color: statusStr(
                                            singleRequest.status.toString()),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.2, end: 0),
                          const SizedBox(height: 24),

                          // Request Type Card (your existing code)
                          _buildInfoCard(
                            icon: Icons.article_outlined,
                            title: "Request Type",
                            content: singleRequest.requestType.toString(),
                            color: primaryColor,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 16),

                          // Reason Card - WITH SAFE CHECK
                          if (hasReason)
                            _buildDetailReasonCard(
                              status: singleRequest.status.toString(),
                              cancellationReason: cancellationReason,
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 150.ms)
                                .slideX(begin: 0.1, end: 0),

                          if (hasReason) const SizedBox(height: 16),

                          // Rest of your existing code...
                          _buildDriverCard(singleRequest)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          // Location / Route info
                          if (singleRequest.isCourier)
                            _buildCourierDetailCard(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 300.ms)
                                .slideY(begin: 0.1, end: 0)
                          else
                            _buildLocationCardWithCheckpoints(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 300.ms)
                                .slideY(begin: 0.1, end: 0),

                          // Package details for courier
                          if (singleRequest.isCourier &&
                              (singleRequest.packageDescription != null ||
                               singleRequest.packageWeight != null ||
                               singleRequest.packageDimensions != null)) ...[
                            const SizedBox(height: 16),
                            _buildPackageDetailCard(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 320.ms)
                                .slideY(begin: 0.1, end: 0),
                          ],

                          // Courier checkpoints detail
                          if (singleRequest.isCourier &&
                              singleRequest.courierCheckpoints.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildCourierCheckpointsDetailCard(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 340.ms)
                                .slideY(begin: 0.1, end: 0),
                          ],

                          // Trip details (distance, fare, times)
                          if (singleRequest.distanceKm != null ||
                              singleRequest.actualFare != null ||
                              singleRequest.pickupTime != null ||
                              singleRequest.dropoffTime != null) ...[
                            const SizedBox(height: 16),
                            _buildTripDetailsCard(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 350.ms)
                                .slideY(begin: 0.1, end: 0),
                          ],

                          // Cancellation info
                          if (singleRequest.cancelledBy != null) ...[
                            const SizedBox(height: 16),
                            _buildCancellationInfoCard(singleRequest)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                          ],
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

  String _activeFilter = 'ALL';
  final List<String> _filterStatuses = ['ALL', 'PENDING', 'APPROVED', 'ONGOING',  'COMPLETED', 'CANCELLED', 'REJECTED'];

  Widget _buildScreenBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(gradient: _RequestsColors.pageGradient),
      child: child,
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Gradient? gradient,
    Color? color,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? _RequestsColors.surface.withOpacity(0.9),
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? _RequestsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRequestsHero(Map<String, int> statusCounts, int filteredCount) {
    final pendingCount = statusCounts['PENDING'] ?? 0;
    final ongoingCount = statusCounts['ONGOING'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: _RequestsColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _RequestsColors.accent.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _RequestsColors.accent.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: 18,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _RequestsColors.accent2.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_RequestsColors.accent, _RequestsColors.accent2],
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
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
                            'Request Activity',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _RequestsColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activeFilter == 'ALL'
                                ? 'Track your rides and courier updates in one place.'
                                : 'Showing $_activeFilter requests only.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _RequestsColors.textMuted,
                              height: 1.35,
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
                    _buildHeroStatChip(
                      'Visible',
                      '$filteredCount',
                      _activeFilter == 'ALL' ? 'requests' : _activeFilter.toLowerCase(),
                      _RequestsColors.accent,
                    ),
                    const SizedBox(width: 8),
                    _buildHeroStatChip(
                      'Pending',
                      '$pendingCount',
                      pendingCount == 1 ? 'awaiting' : 'awaiting',
                      _RequestsColors.amber,
                    ),
                    const SizedBox(width: 8),
                    _buildHeroStatChip(
                      'On Trip',
                      '$ongoingCount',
                      'active now',
                      _RequestsColors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatChip(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _RequestsColors.textSoft,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: _RequestsColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard({
    required String status,
    String? cancellationReason,
  }) {
    String? reason = cancellationReason;
    Color color;
    IconData icon;
    String title;

    if ((status == 'CANCELLED' || status == 'REJECTED') &&
        reason != null &&
        reason.isNotEmpty) {
      if (status == 'CANCELLED') {
        color = Colors.orange;
        icon = Icons.info_outline;
        title = 'Cancellation Reason';
      } else {
        // REJECTED
        color = Colors.red;
        icon = Icons.cancel_outlined;
        title = 'Rejection Reason';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _RequestsColors.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailReasonCard({
    required String status,
    String? cancellationReason,
  }) {
    String? reason = cancellationReason;
    if (!((status == 'CANCELLED' || status == 'REJECTED') &&
        reason != null &&
        reason.isNotEmpty)) {
      return const SizedBox.shrink();
    }

    final isCancelled = status == 'CANCELLED';
    final color = isCancelled ? Colors.orange : Colors.red;
    final icon = isCancelled ? Icons.info_outline_rounded : Icons.cancel_outlined;
    final title = isCancelled ? 'Cancellation Reason' : 'Rejection Reason';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _RequestsColors.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.14),
            _RequestsColors.surface2.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: _RequestsColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _RequestsColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(singleRequest) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RequestsColors.border, width: 1.2),
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
          Row(
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
                      'Motor Biker',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: _RequestsColors.textMuted,
                      ),
                    ),
                    Text(
                      "${singleRequest.motorBiker!.firstName ?? "------"} ${singleRequest.motorBiker!.lastName ?? "------"}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _RequestsColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  FlutterPhoneDirectCaller.callNumber(
                      "+${singleRequest.motorBiker!.phone}");
                },
                icon: const Icon(Icons.phone, size: 14),
                label: Text(
                  "Call",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _RequestsColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, delay: 3000.ms),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _RequestsColors.bg3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _RequestsColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 12, color: _RequestsColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      singleRequest.motorBiker!.phone ?? "------",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _RequestsColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.motorcycle,
                            size: 12, color: _RequestsColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          singleRequest.motorBiker!.motorType.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _RequestsColors.text,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.numbers, size: 12, color: _RequestsColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          singleRequest.motorBiker!.plateNumber.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _RequestsColors.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String origin, String destination) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RequestsColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            icon: CupertinoIcons.location_circle,
            iconColor: Colors.grey[600]!,
            label: "Origin Location",
            location: origin,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 1,
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildLocationRow(
            icon: CupertinoIcons.location_solid,
            iconColor: greenColor,
            label: "Destination Location",
            location: destination,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String location,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: _RequestsColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _RequestsColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Update the BLoC builder in the build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RequestsColors.bg,
      appBar: _buildAppBar(),
      body: _buildScreenBackground(
        child: BlocConsumer<ReceivedSentRequestsBloc, ReceivedSentRequestsState>(
          listener: _handleBlocListener,
          builder: _buildBlocContent,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _handleBlocListener(
      BuildContext context, ReceivedSentRequestsState state) {
    if (state is ReceivedSentRequestsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[400],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildBlocContent(
      BuildContext context, ReceivedSentRequestsState state) {
    if (state is ReceivedSentRequestsLoading) {
      return _buildLoadingState();
    } else if (state is ReceivedSentRequestsSuccess) {
      return _buildSuccessState(state);
    } else if (state is ReceivedSentRequestsInitial) {
      return _buildInitialState();
    } else if (state is ReceivedSentRequestsError) {
      return _buildErrorState(state);
    } else {
      return _buildUnexpectedState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(_RequestsColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _RequestsColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ReceivedSentRequestsSuccess state) {
  if (state.userSentRequestsModel.data == null) {
    return _buildEmptyState();
  }

  final List<RequestContent> allRequests =
      state.userSentRequestsModel.data!.content;

  if (allRequests.isEmpty) {
    return _buildEmptyState();
  }

  // Sort: latest first, then PENDING bubbled to top
  allRequests.sort((a, b) {
    if (a.status == "PENDING" && b.status != "PENDING") return -1;
    if (a.status != "PENDING" && b.status == "PENDING") return 1;
    return 0;
  });

  // Count per status
  Map<String, int> statusCounts = {'ALL': allRequests.length};
  for (var r in allRequests) {
    final s = r.status.toString();
    statusCounts[s] = (statusCounts[s] ?? 0) + 1;
  }

  // Apply filter
  final filtered = _activeFilter == 'ALL'
      ? allRequests
      : allRequests.where((r) => r.status == _activeFilter).toList();

  return RefreshIndicator(
    onRefresh: () async {
      _handleRefresh();
      await Future.delayed(const Duration(milliseconds: 1000));
    },
    color: _RequestsColors.accent,
    child: Column(
      children: [
        _buildRequestsHero(statusCounts, filtered.length)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.12, end: 0),
        _buildGlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterStatuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _filterStatuses[index];
                final count = statusCounts[status] ?? 0;
                final isActive = _activeFilter == status;

                Color chipColor;
                switch (status) {
                  case 'ALL': chipColor = _RequestsColors.accent; break;
                  case 'PENDING': chipColor = _RequestsColors.amber; break;
                  case 'APPROVED': chipColor = _RequestsColors.green; break;
                  case 'ONGOING': chipColor = const Color(0xFF38BDF8); break;
                  case 'COMPLETED': chipColor = const Color(0xFF14B8A6); break;
                  case 'CANCELLED': chipColor = _RequestsColors.textSoft; break;
                  case 'REJECTED': chipColor = _RequestsColors.red; break;
                  default: chipColor = _RequestsColors.textMuted;
                }

                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? chipColor.withOpacity(0.18) : _RequestsColors.bg3,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? chipColor.withOpacity(0.75) : _RequestsColors.border,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: chipColor.withOpacity(0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? _RequestsColors.text : chipColor,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive ? chipColor : chipColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _RequestsColors.text,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ).animate().fadeIn(duration: 420.ms).slideY(begin: -0.1, end: 0),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(context, filtered[index], index)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (50 * index).ms);
                  },
                ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _RequestsColors.bg3,
              shape: BoxShape.circle,
              border: Border.all(color: _RequestsColors.border),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: _RequestsColors.textSoft,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms, duration: 600.ms)
              .then()
              .shimmer(delay: 1000.ms, duration: 1500.ms),
          const SizedBox(height: 24),
          Text(
            'No requests found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _RequestsColors.text,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Your requests will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _RequestsColors.textMuted,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 64, color: _RequestsColors.textSoft),
          const SizedBox(height: 16),
          Text(
            'Pull to load requests',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _RequestsColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReceivedSentRequestsError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: _RequestsColors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading requests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _RequestsColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _RequestsColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _RequestsColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnexpectedState() {
    return Center(
      child: Text(
        'Unexpected state',
        style: GoogleFonts.poppins(fontSize: 16, color: _RequestsColors.textMuted),
      ),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    elevation: 0,
    backgroundColor: _RequestsColors.bg,
    surfaceTintColor: Colors.transparent,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _RequestsColors.text,
          ),
        ),
        if (_activeFilter != 'ALL')
          Text(
            'Filtered: $_activeFilter',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _RequestsColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ).animate().fadeIn(duration: 200.ms),
      ],
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _RequestsColors.text, size: 20),
      onPressed: () => context.safeGoNamed(home),
    ),
    actions: [
      if (_activeFilter != 'ALL')
        IconButton(
          tooltip: 'Clear filter',
          onPressed: () => setState(() => _activeFilter = 'ALL'),
          icon: const Icon(Icons.filter_alt_off_rounded, color: _RequestsColors.text, size: 22),
        ).animate().fadeIn(duration: 200.ms),
      IconButton(
        onPressed: _handleRefresh,
        icon: RotationTransition(
          turns: _refreshController,
          child: const Icon(Icons.sync, color: _RequestsColors.text, size: 28),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}
  Widget _buildBottomBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _RequestsColors.bg2,
        border: const Border(
          top: BorderSide(color: _RequestsColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Powered by Mopay",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _RequestsColors.textSoft,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

Widget _buildRequestCard(BuildContext context, request, int index) {
  String? cancellationReason;
  try {
    cancellationReason = request.cancellationReason?.toString();
  } catch (e) {
    cancellationReason = null;
  }

  final bool hasReason =
      (request.status == 'CANCELLED' || request.status == 'REJECTED') &&
          cancellationReason != null &&
          cancellationReason.isNotEmpty;

  final Color statusColor = statusStr(request.status.toString());
  final bool isCourier = request.isCourier;
  final Color typeAccent = isCourier ? const Color(0xFF1F69A2) : primaryColor;

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _RequestsColors.surface.withOpacity(0.96),
          _RequestsColors.surface2.withOpacity(0.96),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _RequestsColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.22),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.18),
                  statusColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeAccent, typeAccent.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: typeAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isCourier ? Icons.local_shipping_rounded : Icons.motorcycle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + type label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.motorBiker?.firstName ?? '---'} ${request.motorBiker?.lastName ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _RequestsColors.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeAccent.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeAccent.withOpacity(0.24)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCourier ? Icons.inventory_2_outlined : Icons.two_wheeler,
                                  size: 10,
                                  color: typeAccent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  request.requestType.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: typeAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.access_time_rounded, size: 10, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            request.requestedTime != null
                                ? _formatDateTime(request.requestedTime.toString())
                                : '---',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: _RequestsColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon(request.status.toString()), size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        request.status.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(delay: 2000.ms, duration: 1500.ms),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route card (different for RIDE vs COURIER)
                if (isCourier)
                  _buildCourierRouteCard(request)
                else
                  _buildRouteCard(request),

                // Package info for courier
                if (isCourier && (request.packageDescription != null || request.packageWeight != null)) ...[
                  const SizedBox(height: 10),
                  _buildPackageInfoCard(request),
                ],

                // Courier checkpoints
                if (isCourier && request.courierCheckpoints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildCourierCheckpointsSummary(request),
                ],

                // Trip info (distance & fare)
                if (request.distanceKm != null || request.actualFare != null) ...[
                  const SizedBox(height: 10),
                  _buildTripInfoRow(request),
                ],

                // Pickup / Dropoff times
                if (request.pickupTime != null || request.dropoffTime != null) ...[
                  const SizedBox(height: 10),
                  _buildTimesRow(request),
                ],

                // Cancellation / rejection reason
                if (hasReason) ...[
                  const SizedBox(height: 10),
                  _buildEnhancedReasonCard(
                    status: request.status.toString(),
                    reason: cancellationReason!,
                  ),
                ],

                // Cancelled by info
                if (request.cancelledBy != null) ...[
                  const SizedBox(height: 8),
                  _buildCancelledByChip(request),
                ],

                const SizedBox(height: 10),

                // ── Action Buttons ───────────────────────────────
                Row(
                  children: [
                    // View Details — always visible
                    Expanded(
                      child: _buildEnhancedActionButton(
                        icon: Icons.info_outline_rounded,
                        label: 'Details',
                        color: primaryColor,
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        onTap: () => showRequestDetails(context, request),
                      ),
                    ),

                    // View Map — ONGOING or APPROVED or DRIVER_ARRIVING only
                    if (request.status == "ONGOING" || request.status == "APPROVED" || request.status == "DRIVER_ARRIVING" || request.status == "IN_PROGRESS") ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEnhancedActionButton(
                          icon: Icons.map_outlined,
                          label: 'View Map',
                          color: Colors.orange,
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          onTap: () {
                            context.safeGoNamed(clientDirections, params: {
                              'requestId': request.id.toString(),
                              'originLocation': request.originLocation.toString(),
                              'destinationLocation': request.destinationLocation.toString(),
                              'clientNames': '${request.client?.fname} ${request.client?.lname}',
                              'clientPhone': '${request.client?.phone}',
                              'driverName': '${request.driverName}',
                              'driverPhone': '${request.driverPhone}',
                            });
                          },
                        ),
                      ),
                    ],

                    // Cancel — PENDING only
                    if (request.status == "PENDING") ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: BlocConsumer<UpdateSentRequestStatusBloc,
                            UpdateSentRequestStatusState>(
                          listener: (context, state) {
                            if (state is UpdateSentRequestStatusSuccess) {
                              showSuccessAlert(
                                state.updateSentRequestModel.message.toString(),
                                context,
                              );
                              _loadUserRequests();
                            }
                            if (state is UpdateSentRequestStatusError) {
                              showErrorAlert(state.message.toString(), context);
                            }
                          },
                          builder: (context, state) {
                            return _buildEnhancedActionButton(
                              icon: Icons.cancel_outlined,
                              label: 'Cancel',
                              color: Colors.red,
                              gradient: const LinearGradient(
                                colors: [Colors.red, Color(0xFFc62828)],
                              ),
                              onTap: () => _showCancelBottomSheet(context, request.id!.toInt()),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Courier route card showing courierFrom -> courierTo
  Widget _buildCourierRouteCard(RequestContent request) {
    final from = request.courierFrom;
    final to = request.courierTo;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F69A2).withOpacity(0.28)),
      ),
      child: Column(
        children: [
          // From
          _buildCourierLocationRow(
            icon: Icons.warehouse_outlined,
            iconColor: const Color(0xFF1F69A2),
            label: "Pickup",
            locationName: from?.name ?? request.originLocation?.name ?? '---',
            receiverName: from?.receiverName,
            receiverPhone: from?.receiverPhone,
          ),
          // Courier checkpoints (inline dots)
          if (request.courierCheckpoints.isNotEmpty)
            ...request.courierCheckpoints.map((cp) => Column(
              children: [
                _buildDottedConnector(),
                _buildCourierLocationRow(
                  icon: Icons.local_shipping_outlined,
                  iconColor: Colors.deepPurple.shade300,
                  label: "Drop ${cp.order ?? ''}",
                  locationName: cp.name ?? '---',
                  receiverName: cp.receiverName,
                  receiverPhone: cp.receiverPhone,
                  checkpointStatus: cp.checkpointStatus,
                ),
              ],
            )),
          _buildDottedConnector(),
          // To
          _buildCourierLocationRow(
            icon: Icons.flag_rounded,
            iconColor: Colors.orange.shade700,
            label: "Final Destination",
            locationName: to?.name ?? request.destinationLocation ?? '---',
            receiverName: to?.receiverName,
            receiverPhone: to?.receiverPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildCourierLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String locationName,
    String? receiverName,
    String? receiverPhone,
    String? checkpointStatus,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: _RequestsColors.textMuted,
                    ),
                  ),
                  if (checkpointStatus != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _checkpointStatusColor(checkpointStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        checkpointStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: _checkpointStatusColor(checkpointStatus),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                locationName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _RequestsColors.text,
                ),
              ),
              if (receiverName != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      receiverName,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _RequestsColors.textMuted,
                      ),
                    ),
                    if (receiverPhone != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.phone_outlined, size: 9, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        receiverPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: _RequestsColors.textSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _checkpointStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return const Color(0xFF00796B);
      case 'IN_PROGRESS': return const Color(0xFF1565C0);
      case 'PENDING': return const Color(0xFFF57C00);
      default: return const Color(0xFF546E7A);
    }
  }

  /// Package info summary card for courier requests
  Widget _buildPackageInfoCard(RequestContent request) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.bg3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 16, color: Colors.amber.shade800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.packageDescription != null)
                  Text(
                    request.packageDescription!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _RequestsColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    if (request.packageWeight != null) ...[
                      Icon(Icons.scale_outlined, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        request.packageWeight!,
                        style: GoogleFonts.poppins(fontSize: 10, color: _RequestsColors.textMuted),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (request.packageDimensions != null) ...[
                      Icon(Icons.straighten_outlined, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          request.packageDimensions!,
                          style: GoogleFonts.poppins(fontSize: 10, color: _RequestsColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (request.declaredValue != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.monetization_on_outlined, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        '${request.declaredValue!.toStringAsFixed(0)} TZS',
                        style: GoogleFonts.poppins(fontSize: 10, color: _RequestsColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Summary of courier checkpoints count and status
  Widget _buildCourierCheckpointsSummary(RequestContent request) {
    final total = request.courierCheckpoints.length;
    final completed = request.courierCheckpoints.where(
      (cp) => cp.checkpointStatus?.toUpperCase() == 'COMPLETED'
    ).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.shade100.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_rounded, size: 14, color: Colors.deepPurple.shade400),
          const SizedBox(width: 8),
          Text(
            '$completed / $total deliveries',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const Spacer(),
          // Progress indicator
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                backgroundColor: Colors.deepPurple.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedReasonCard({
    required String status,
    required String reason,
  }) {
    final isCancelled = status == 'CANCELLED';
    final color = isCancelled ? Colors.orange : Colors.red;
    final icon = isCancelled ? Icons.info_outline_rounded : Icons.cancel_outlined;
    final title = isCancelled ? 'Cancellation Reason' : 'Rejection Reason';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _RequestsColors.text,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// Route card with origin, checkpoints, and destination
  Widget _buildRouteCard(RequestContent request) {
    final checkpoints = request.checkpoints;
    final hasCheckpoints = checkpoints.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _RequestsColors.border),
      ),
      child: Column(
        children: [
          // Origin
          _buildLocationRow(
            icon: CupertinoIcons.location_circle,
            iconColor: primaryColor,
            label: "Origin",
            location: request.originLocation.toString(),
          ),
          // Checkpoints
          if (hasCheckpoints)
            ...checkpoints.map((cp) => Column(
              children: [
                _buildDottedConnector(),
                _buildLocationRow(
                  icon: Icons.flag_circle_rounded,
                  iconColor: Colors.blue.shade400,
                  label: "Stop ${cp.order ?? ''}",
                  location: cp.name ?? '---',
                ),
              ],
            )),
          // Connector
          _buildDottedConnector(),
          // Destination
          _buildLocationRow(
            icon: CupertinoIcons.location_solid,
            iconColor: Colors.orange,
            label: "Destination",
            location: request.destinationLocation.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
      child: Row(
        children: List.generate(
          3,
          (_) => Container(
            width: 2,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: _RequestsColors.textSoft,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  /// Trip info chips (distance & fare) for the card list
  Widget _buildTripInfoRow(RequestContent request) {
    return Row(
      children: [
        if (request.distanceKm != null)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten_rounded, size: 13, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${request.distanceKm!.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (request.distanceKm != null && request.actualFare != null)
          const SizedBox(width: 8),
        if (request.actualFare != null)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${request.actualFare!.toStringAsFixed(0)} TZS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Pickup & dropoff times row for the card list
  Widget _buildTimesRow(RequestContent request) {
    return Row(
      children: [
        if (request.pickupTime != null)
          Expanded(
            child: _buildTimeChip(
              icon: Icons.hail_rounded,
              label: 'Pickup',
              time: _formatTime(request.pickupTime),
              color: Colors.teal,
            ),
          ),
        if (request.pickupTime != null && request.dropoffTime != null)
          const SizedBox(width: 8),
        if (request.dropoffTime != null)
          Expanded(
            child: _buildTimeChip(
              icon: Icons.where_to_vote_rounded,
              label: 'Dropoff',
              time: _formatTime(request.dropoffTime),
              color: Colors.indigo,
            ),
          ),
      ],
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: _RequestsColors.textMuted,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cancelled-by chip for the card list
  Widget _buildCancelledByChip(RequestContent request) {
    final isByClient = request.cancelledBy?.toUpperCase() == 'CLIENT';
    return Row(
      children: [
        Icon(
          isByClient ? Icons.person_outline : Icons.motorcycle,
          size: 12,
          color: _RequestsColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          'Cancelled by ${isByClient ? 'Client' : 'Driver'}',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _RequestsColors.textMuted,
          ),
        ),
        if (request.cancelledAt != null) ...[
          const SizedBox(width: 6),
          Text(
            '• ${_formatTime(request.cancelledAt)}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: _RequestsColors.textSoft,
            ),
          ),
        ],
      ],
    );
  }

  /// Location card with checkpoints for the detail bottom sheet
  Widget _buildLocationCardWithCheckpoints(RequestContent request) {
    final checkpoints = request.checkpoints;
    final hasCheckpoints = checkpoints.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _RequestsColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RequestsColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            icon: CupertinoIcons.location_circle,
            iconColor: Colors.grey[600]!,
            label: "Origin Location",
            location: request.originLocation.toString(),
          ),
          if (hasCheckpoints)
            ...checkpoints.map((cp) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Column(
                        children: List.generate(
                          3,
                          (index) => Container(
                            width: 2,
                            height: 3,
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue[200],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLocationRow(
                  icon: Icons.flag_circle_rounded,
                  iconColor: Colors.blue.shade400,
                  label: "Checkpoint ${cp.order ?? ''}",
                  location: cp.name ?? '---',
                ),
              ],
            )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 2,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: _RequestsColors.textSoft,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildLocationRow(
            icon: CupertinoIcons.location_solid,
            iconColor: greenColor,
            label: "Destination Location",
            location: request.destinationLocation.toString(),
          ),
        ],
      ),
    );
  }

  /// Trip details card for the detail bottom sheet
  Widget _buildTripDetailsCard(RequestContent request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RequestsColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RequestsColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _RequestsColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (request.distanceKm != null)
                Expanded(child: _buildMetricTile(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: '${request.distanceKm!.toStringAsFixed(1)} km',
                  color: Colors.blue,
                )),
              if (request.distanceKm != null && request.actualFare != null)
                const SizedBox(width: 12),
              if (request.actualFare != null)
                Expanded(child: _buildMetricTile(
                  icon: Icons.payments_outlined,
                  label: 'Fare',
                  value: '${request.actualFare!.toStringAsFixed(0)} TZS',
                  color: Colors.green,
                )),
            ],
          ),
          if (request.pickupTime != null || request.dropoffTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (request.pickupTime != null)
                  Expanded(child: _buildMetricTile(
                    icon: Icons.hail_rounded,
                    label: 'Pickup',
                    value: _formatDateTime(request.pickupTime),
                    color: Colors.teal,
                  )),
                if (request.pickupTime != null && request.dropoffTime != null)
                  const SizedBox(width: 12),
                if (request.dropoffTime != null)
                  Expanded(child: _buildMetricTile(
                    icon: Icons.where_to_vote_rounded,
                    label: 'Dropoff',
                    value: _formatDateTime(request.dropoffTime),
                    color: Colors.indigo,
                  )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _RequestsColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Cancellation info card for the detail bottom sheet
  Widget _buildCancellationInfoCard(RequestContent request) {
    final isByClient = request.cancelledBy?.toUpperCase() == 'CLIENT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _RequestsColors.bg3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _RequestsColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isByClient ? Icons.person_outline : Icons.motorcycle,
            size: 16,
            color: _RequestsColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            'Cancelled by ${isByClient ? 'Client' : 'Driver'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _RequestsColors.textMuted,
            ),
          ),
          if (request.cancelledAt != null) ...[
            const Spacer(),
            Text(
              _formatDateTime(request.cancelledAt),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _RequestsColors.textSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '---';
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '---';
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

Widget _buildEnhancedActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required Gradient gradient,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 38,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  )
      .animate()
      .fadeIn(duration: 300.ms)
      .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
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

  /// Courier full detail card for bottom sheet (origin → stops → destination)
  Widget _buildCourierDetailCard(RequestContent request) {
    final from = request.courierFrom;
    final to = request.courierTo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, size: 16, color: Colors.deepPurple.shade400),
              const SizedBox(width: 8),
              Text(
                'Courier Route',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // From
          _buildDetailCourierStop(
            icon: Icons.warehouse_outlined,
            iconColor: const Color(0xFF1F69A2),
            label: 'Pickup Location',
            name: from?.name ?? request.originLocation?.name ?? '---',
            receiverName: from?.receiverName,
            receiverPhone: from?.receiverPhone,
            driverApproval: from?.driverApprovalRequired,
            driverApproved: from?.driverApproved,
          ),
          // Courier checkpoints
          if (request.courierCheckpoints.isNotEmpty)
            ...request.courierCheckpoints.map((cp) => Column(
              children: [
                _buildDetailDottedLine(Colors.deepPurple.shade200),
                _buildDetailCourierStop(
                  icon: Icons.local_shipping_outlined,
                  iconColor: Colors.deepPurple.shade300,
                  label: 'Delivery Stop ${cp.order ?? ''}',
                  name: cp.name ?? '---',
                  receiverName: cp.receiverName,
                  receiverPhone: cp.receiverPhone,
                  checkpointStatus: cp.checkpointStatus,
                  otpVerified: cp.otpVerified,
                ),
              ],
            )),
          _buildDetailDottedLine(Colors.grey.shade300),
          // To
          _buildDetailCourierStop(
            icon: Icons.flag_rounded,
            iconColor: Colors.orange.shade700,
            label: 'Final Destination',
            name: to?.name ?? request.destinationLocation ?? '---',
            receiverName: to?.receiverName,
            receiverPhone: to?.receiverPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCourierStop({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String name,
    String? receiverName,
    String? receiverPhone,
    bool? driverApproval,
    bool? driverApproved,
    String? checkpointStatus,
    bool? otpVerified,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (checkpointStatus != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _checkpointStatusColor(checkpointStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _checkpointStatusColor(checkpointStatus).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        checkpointStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: _checkpointStatusColor(checkpointStatus),
                        ),
                      ),
                    ),
                  ],
                  if (otpVerified == true) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade600),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (receiverName != null || receiverPhone != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      if (receiverName != null)
                        Text(
                          receiverName,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (receiverPhone != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.phone_outlined, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(
                          receiverPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (driverApproval == true) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      driverApproved == true ? Icons.check_circle : Icons.pending,
                      size: 12,
                      color: driverApproved == true ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driverApproved == true ? 'Driver approved' : 'Awaiting driver approval',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: driverApproved == true ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailDottedLine(Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            width: 2,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  /// Package detail card for bottom sheet
  Widget _buildPackageDetailCard(RequestContent request) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_rounded, size: 18, color: Colors.amber.shade800),
              ),
              const SizedBox(width: 10),
              Text(
                'Package Details',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (request.packageDescription != null)
                _buildPackageDetailItem(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: request.packageDescription!,
                  color: Colors.blue,
                ),
              if (request.packageWeight != null)
                _buildPackageDetailItem(
                  icon: Icons.scale_outlined,
                  label: 'Weight',
                  value: request.packageWeight!,
                  color: Colors.teal,
                ),
              if (request.packageDimensions != null)
                _buildPackageDetailItem(
                  icon: Icons.straighten_outlined,
                  label: 'Dimensions',
                  value: request.packageDimensions!,
                  color: Colors.indigo,
                ),
              if (request.declaredValue != null)
                _buildPackageDetailItem(
                  icon: Icons.monetization_on_outlined,
                  label: 'Declared Value',
                  value: '${request.declaredValue!.toStringAsFixed(0)} TZS',
                  color: Colors.green,
                ),
              if (request.specialInstructions != null)
                _buildPackageDetailItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Special Instructions',
                  value: request.specialInstructions!,
                  color: Colors.orange,
                  fullWidth: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Courier checkpoints detail card for bottom sheet
  Widget _buildCourierCheckpointsDetailCard(RequestContent request) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 16, color: Colors.deepPurple.shade400),
              const SizedBox(width: 8),
              Text(
                'Delivery Stops',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '${request.courierCheckpoints.where((c) => c.checkpointStatus?.toUpperCase() == 'COMPLETED').length}/${request.courierCheckpoints.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...request.courierCheckpoints.map((cp) {
            final isCompleted = cp.checkpointStatus?.toUpperCase() == 'COMPLETED';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade50.withOpacity(0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check, size: 14, color: Colors.green.shade700)
                              : Text(
                                  '${cp.order ?? ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cp.name ?? '---',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (cp.checkpointStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _checkpointStatusColor(cp.checkpointStatus!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cp.checkpointStatus!,
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _checkpointStatusColor(cp.checkpointStatus!),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (cp.receiverName != null || cp.packageDescription != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (cp.receiverName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline, size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                cp.receiverName!,
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (cp.receiverPhone != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                cp.receiverPhone!,
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (cp.packageDescription != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                cp.packageDescription!,
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (cp.packageWeight != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.scale_outlined, size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                cp.packageWeight!,
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        if (cp.otpVerified == true)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 11, color: Colors.green.shade600),
                              const SizedBox(width: 3),
                              Text(
                                'OTP Verified',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  // Delivery notes & approval info
                  if (cp.deliveryNotes != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 11, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cp.deliveryNotes!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (cp.approvedBy != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.approval_rounded, size: 11, color: Colors.teal.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Approved by ${cp.approvedBy!}',
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.teal.shade700),
                        ),
                        if (cp.approvedDateTime != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${cp.approvedDateTime!.hour.toString().padLeft(2, '0')}:${cp.approvedDateTime!.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(fontSize: 9, color: Colors.teal.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (cp.completedDateTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 11, color: Colors.green.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Completed at ${cp.completedDateTime!.hour.toString().padLeft(2, '0')}:${cp.completedDateTime!.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.green.shade600),
                        ),
                      ],
                    ),
                  ],
                  if (cp.specialInstructions != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 11, color: Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cp.specialInstructions!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReasonSection(String status, String? cancellationReason) {
    // Determine which reason to show and the appropriate styling
    String? reason = cancellationReason;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;

    // Only show for CANCELLED or REJECTED status with a valid reason
    if ((status == 'CANCELLED' || status == 'REJECTED') &&
        reason != null &&
        reason.isNotEmpty) {
      if (status == 'CANCELLED') {
        backgroundColor = Colors.orange.withOpacity(0.1);
        borderColor = Colors.orange.withOpacity(0.3);
        textColor = Colors.orange.shade700;
        icon = Icons.info_outline;
        title = 'Cancellation Reason';
      } else {
        // REJECTED
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red.withOpacity(0.3);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        title = 'Rejection Reason';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}