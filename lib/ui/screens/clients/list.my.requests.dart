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
              decoration: const BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
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
                      color: Colors.grey[300],
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

                          _buildLocationCard(
                            singleRequest.originLocation.toString(),
                            singleRequest.destinationLocation.toString(),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideY(begin: 0.1, end: 0),
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
                    color: Colors.black87,
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
    Color primaryColor;
    Color backgroundColor;
    Color borderColor;
    IconData icon;
    String title;

    if ((status == 'CANCELLED' || status == 'REJECTED') &&
        reason != null &&
        reason.isNotEmpty) {
      if (status == 'CANCELLED') {
        primaryColor = Colors.orange.shade700;
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        icon = Icons.info_outline_rounded;
        title = 'Cancellation Reason';
      } else {
        primaryColor = Colors.red.shade700;
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        icon = Icons.cancel_outlined;
        title = 'Rejection Reason';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              reason,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.6,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms)
        .shimmer(delay: 800.ms, duration: 1500.ms);
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
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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

  Widget _buildDriverCard(singleRequest) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      "${singleRequest.motorBiker!.firstName ?? "------"} ${singleRequest.motorBiker!.lastName ?? "------"}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  FlutterPhoneDirectCaller.callNumber(
                      "+"+singleRequest.motorBiker!.phone.toString());
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
                  backgroundColor: primaryColor,
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      singleRequest.motorBiker!.phone ?? "------",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          singleRequest.motorBiker!.motorType.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.numbers, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          singleRequest.motorBiker!.plateNumber.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
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
                  color: Colors.grey[600],
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
                  color: Colors.black87,
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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: BlocConsumer<ReceivedSentRequestsBloc, ReceivedSentRequestsState>(
        listener: _handleBlocListener,
        builder: _buildBlocContent,
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
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
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
    color: primaryColor,
    child: Column(
      children: [
        // Filter Chips Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                  case 'ALL': chipColor = primaryColor; break;
                  case 'PENDING': chipColor = Colors.orange; break;
                  case 'APPROVED': chipColor = Colors.green; break;
                  case 'ONGOING': chipColor = Colors.blue; break;
                  case 'CANCELLED': chipColor = Colors.grey; break;
                  case 'REJECTED': chipColor = Colors.red; break;
                  default: chipColor = Colors.black;
                }

                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? chipColor : chipColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? chipColor : chipColor.withOpacity(0.4),
                        width: isActive ? 0 : 1,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: chipColor.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
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
                            color: isActive ? Colors.white : chipColor,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withOpacity(0.3)
                                  : chipColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

        // Divider
        Container(height: 1, color: Colors.grey[100]),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
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
              color: Colors.grey[700],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Your requests will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
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
          Icon(Icons.refresh, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Pull to load requests',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading requests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
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
                color: Colors.grey[600],
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
              backgroundColor: primaryColor,
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
        style: GoogleFonts.poppins(fontSize: 16),
      ),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    elevation: 0,
    backgroundColor: primaryColor,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        if (_activeFilter != 'ALL')
          Text(
            'Filtered: $_activeFilter',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ).animate().fadeIn(duration: 200.ms),
      ],
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      onPressed: () => context.safeGoNamed(home),
    ),
    actions: [
      if (_activeFilter != 'ALL')
        IconButton(
          tooltip: 'Clear filter',
          onPressed: () => setState(() => _activeFilter = 'ALL'),
          icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.white, size: 22),
        ).animate().fadeIn(duration: 200.ms),
      IconButton(
        onPressed: _handleRefresh,
        icon: RotationTransition(
          turns: _refreshController,
          child: const Icon(Icons.sync, color: Colors.white, size: 28),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Powered by Besoft & BePay ltd",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
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

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
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
                  statusColor.withOpacity(0.13),
                  statusColor.withOpacity(0.04),
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
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (request.motorBiker?.firstName ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.motorBiker?.firstName ?? '---'} ${request.motorBiker?.lastName ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.motorcycle, size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Motor Biker',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
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
                    color: statusColor,
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
                // Request type + date row
                Row(
                  children: [
                    // Request type chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined, color: primaryColor, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            request.requestType.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          request.requestedTime != null
                              ? request.requestedTime.toString().substring(0, 10)
                              : '---',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Location card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildLocationRow(
                        icon: CupertinoIcons.location_circle,
                        iconColor: primaryColor,
                        label: "Origin",
                        location: request.originLocation.toString(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                        child: Row(
                          children: List.generate(
                            3,
                            (_) => Container(
                              width: 2,
                              height: 3,
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildLocationRow(
                        icon: CupertinoIcons.location_solid,
                        iconColor: Colors.orange,
                        label: "Destination",
                        location: request.destinationLocation.toString(),
                      ),
                    ],
                  ),
                ),

                // Cancellation / rejection reason
                if (hasReason) ...[
                  const SizedBox(height: 10),
                  _buildEnhancedReasonCard(
                    status: request.status.toString(),
                    reason: cancellationReason!,
                  ),
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

                    // View Map — ONGOING or APPROVED
                    if (request.status == "ONGOING" || request.status == "APPROVED") ...[
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
                              'driverNames': '${request.driverName}',
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

// NEW: Enhanced reason card widget
  Widget _buildEnhancedReasonCard({
    required String status,
    required String reason,
  }) {
    Color primaryColor;
    Color backgroundColor;
    Color borderColor;
    IconData icon;
    String title;

    if (status == 'CANCELLED') {
      primaryColor = Colors.orange.shade700;
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      icon = Icons.info_outline_rounded;
      title = 'Cancellation Reason';
    } else {
      // REJECTED
      primaryColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      icon = Icons.cancel_outlined;
      title = 'Rejection Reason';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.2),
                  primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms)
        .shimmer(delay: 1000.ms, duration: 1500.ms);
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
