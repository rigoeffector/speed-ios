import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CancellationReason {
  final String title;
  final String description;
  final String kinyaDescription;
  final IconData icon;

  CancellationReason({
    required this.title,
    required this.description,
    required this.kinyaDescription,
    required this.icon,
  });
}

class CancelRequestBottomSheet extends StatefulWidget {
  final Function(String reason) onConfirmCancel;

  const CancelRequestBottomSheet({
    Key? key,
    required this.onConfirmCancel,
  }) : super(key: key);

  @override
  State<CancelRequestBottomSheet> createState() =>
      _CancelRequestBottomSheetState();
}

class _CancelRequestBottomSheetState extends State<CancelRequestBottomSheet> {
  String? selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<CancellationReason> cancellationReasons = [
    CancellationReason(
      title: "Changed my mind",
      description: "I no longer need this service",
      kinyaDescription: "Nahinduye ibitekerezo",
      icon: Icons.psychology_outlined,
    ),
    CancellationReason(
      title: "Found alternative transport",
      description: "Got another ride or delivery option",
      kinyaDescription: "Nabonye indi modoka",
      icon: Icons.directions_car_outlined,
    ),
    CancellationReason(
      title: "Driver is taking too long",
      description: "Waiting time is too long",
      kinyaDescription: "Umushoferi atinze cyane kuza",
      icon: Icons.access_time_outlined,
    ),
    CancellationReason(
      title: "Wrong pickup location",
      description: "I entered the wrong address",
      kinyaDescription: "Nashyizemo ikerecyezo uri bumfatireho kitari cyo",
      icon: Icons.wrong_location_outlined,
    ),
    CancellationReason(
      title: "Price concerns",
      description: "The fare is too expensive",
      kinyaDescription: "Igiciro kiri hejuru cyane",
      icon: Icons.money_off_outlined,
    ),
    CancellationReason(
      title: "Emergency situation",
      description: "Unexpected urgent matter came up",
      kinyaDescription: "Habaye ikibazo cyihutirwa",
      icon: Icons.emergency_outlined,
    ),
    CancellationReason(
      title: "Driver not responding",
      description: "Cannot reach the driver",
      kinyaDescription: "Umushoferi ntiyasubije",
      icon: Icons.phone_disabled_outlined,
    ),
    CancellationReason(
      title: "Other reason",
      description: "Specify your own reason",
      kinyaDescription: "Andika indi mpamvu yawe",
      icon: Icons.edit_note_outlined,
    ),
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancel Request',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Please select a reason',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

          const Divider(height: 24),

          // Reasons list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cancellationReasons.length,
              itemBuilder: (context, index) {
                final reason = cancellationReasons[index];
                final isSelected = selectedReason == reason.title;
                final isOther = reason.title == "Other reason";

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedReason = reason.title;
                          if (!isOther) {
                            _customReasonController.clear();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.08)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected ? primaryColor : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withOpacity(0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                reason.icon,
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey[600],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reason.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: reason.title,
                              groupValue: selectedReason,
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value;
                                  if (!isOther) {
                                    _customReasonController.clear();
                                  }
                                });
                              },
                              activeColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                        .slideX(begin: 0.2, end: 0, delay: (50 * index).ms),

                    // Custom reason text field
                    if (isOther && isSelected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _customReasonController,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: 'Enter your reason here...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.2, end: 0),
                  ],
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedReason == null
                        ? null
                        : () {
                            String finalReason = selectedReason!;
                            if (selectedReason == "Other reason" &&
                                _customReasonController.text.isNotEmpty) {
                              finalReason = _customReasonController.text;
                            }
                            Navigator.pop(context);
                            widget.onConfirmCancel(finalReason);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedReason == null
                          ? Colors.grey[300]
                          : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(
                      'Confirm Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
