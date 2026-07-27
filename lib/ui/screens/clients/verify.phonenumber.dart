import 'dart:async';
import 'dart:convert';

import 'package:speed_ios/routes/routes.provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_field/intl_phone_number_field.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/routes.names.dart';
import '../../../states/register.client/register_client_bloc.dart';
import '../../../states/verify/verify_otp_bloc.dart';
import '../../../utils/colors.dart';
import '../../../utils/notifiers.dart';

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

class VerifyPhoneNumber extends StatefulWidget {
  final String? deviceToken;

  const VerifyPhoneNumber({Key? key, this.deviceToken}) : super(key: key);

  @override
  State<VerifyPhoneNumber> createState() => _VerifyPhoneNumberState();
}

class _VerifyPhoneNumberState extends State<VerifyPhoneNumber>
    with TickerProviderStateMixin {
  late RegisterClientBloc registerClientBloc;
  late VerifyOtpBloc verifyOtpBloc;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();
final TextEditingController _referralCodeController = TextEditingController(); // NEW
  final _firestore = FirebaseFirestore.instance;

  String? token;
  String? countryCode;
  String? phoneNumber;
  bool isRegisterLoading = false;

  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    registerClientBloc = BlocProvider.of<RegisterClientBloc>(context);
    verifyOtpBloc = BlocProvider.of<VerifyOtpBloc>(context);
    _initializeAnimations();
    token = widget.deviceToken;
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void sendVerificationCode(String userId, String token) async {
    saveToken(token.toString(), userId);
  }

  void saveToken(String token, String userId) async {
    await _firestore
        .collection('clientTokens')
        .doc(userId)
        .set({'token': token});
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
      _referralCodeController.dispose(); // NEW
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<String> loadFromJson() async {
    return rootBundle.loadString('assets/countries/country_list.json');
  }

  void _showPhoneConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _AppColors.bg3,
              border: Border.all(
                color: _AppColors.border,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: whiteColor,
                    size: 32,
                  ),
                )
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1000.ms),
                const SizedBox(height: 20),
                Text(
                  'Verify Phone Number',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: primaryColor,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Is this phone number correct?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.08),
                        primaryColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        phoneNumber.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(
                    begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            'pendingVerification',
                            phoneNumber!,
                          );
                          await prefs.remove('currentUser');
                          await prefs.remove('currentUserProfile');

                          registerClientBloc.add(
                            HandleRegisterClientInformation(
                              phone: phoneNumber!,
                              deviceToken: token.toString(),
                              countryCode: countryCode.toString(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            color: whiteColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOtpVerificationBottomSheet(BuildContext context) {
  final parentContext = this.context;
  final otpController = TextEditingController();
  int resendTimer = 60;
  Timer? countdownTimer;
  bool canResend = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setBottomSheetState) {
          countdownTimer ??=
              Timer.periodic(const Duration(seconds: 1), (timer) {
            if (resendTimer > 0) {
              setBottomSheetState(() {
                resendTimer--;
              });
            } else {
              setBottomSheetState(() {
                canResend = true;
              });
              timer.cancel();
            }
          });

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: _AppColors.bg2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ============================================
                  // SECTION: Drag handle
                  // ============================================
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ============================================
                  // SECTION: Icon
                  // ============================================
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: _AppColors.gradientRide,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // SECTION: Title + subtitle
                  // ============================================
                  Text(
                    'Verify OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.txt,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Enter the 6-digit code sent to',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _AppColors.txt2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _AppColors.bg4,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _AppColors.border,
                      ),
                    ),
                    child: Text(
                      phoneNumber.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _AppColors.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ============================================
                  // SECTION: OTP input (Pinput)
                  // ============================================
                  Pinput(
                    controller: otpController,
                    length: 6,
                    defaultPinTheme: PinTheme(
                      width: 52,
                      height: 58,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.txt,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.bg4,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _AppColors.border,
                        ),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 52,
                      height: 58,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.txt,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.bg4,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                    errorPinTheme: PinTheme(
                      width: 52,
                      height: 58,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.red,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.bg4,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _AppColors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // ============================================
                  // SECTION: Referral code (NEW — optional field)
                  // ============================================
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          'Referral code',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.txt2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _AppColors.bg4,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Optional',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.txt3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _referralCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: _AppColors.txt,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter code if you have one',
                      hintStyle: GoogleFonts.poppins(
                        color: _AppColors.txt3,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: _AppColors.bg4,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // ============================================
                  // SECTION: Resend OTP row
                  // ============================================
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code?',
                        style: GoogleFonts.dmSans(
                          color: _AppColors.txt2,
                        ),
                      ),
                      BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
                        listener: (context, state) {
                          if (state is ResendOtpSuccess) {
                            showSuccessAlert(state.message, context);

                            setBottomSheetState(() {
                              resendTimer = 60;
                              canResend = false;
                            });
                          }

                          if (state is ResendOtpError) {
                            showErrorAlert(state.message, context);
                          }
                        },
                        builder: (context, state) {
                          return TextButton(
                            onPressed: canResend && state is! ResendOtpLoading
                                ? () {
                                    verifyOtpBloc.add(
                                      HandleResendOtp(
                                        phone:
                                            phoneNumber!.replaceAll(' ', ''),
                                      ),
                                    );
                                  }
                                : null,
                            child: state is ResendOtpLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    canResend ? 'Resend' : '${resendTimer}s',
                                    style: GoogleFonts.poppins(
                                      color: canResend
                                          ? _AppColors.accent
                                          : _AppColors.txt3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),

                  // ============================================
                  // SECTION: Verify OTP button
                  // ============================================
                  const SizedBox(height: 28),

                  BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
                    listener: (context, state) async {
                      if (state is VerifyOtpSuccess) {
                        countdownTimer?.cancel();

                        final data = state.verifyOtpModel.data;
                        final String obtainedFname =
                            data?.fname?.toString() ?? '';
                        final String obtainedLname =
                            data?.lname?.toString() ?? '';
                        final String obtainedClientId =
                            data?.id?.toString() ?? '';

                        if (obtainedClientId.isEmpty) {
                          showErrorAlert(
                              'Invalid user data received', parentContext);
                          return;
                        }

                        sendVerificationCode(obtainedClientId, token ?? '');

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('pendingVerification');
                        await prefs.setString(
                            'currentUser', jsonEncode(data?.toJson()));

                        final bool hasProfile = obtainedFname.isNotEmpty &&
                            obtainedFname != 'null' &&
                            obtainedLname.isNotEmpty &&
                            obtainedLname != 'null';

                        if (hasProfile) {
                          await prefs.setString('currentUserProfile',
                              jsonEncode(data?.toJson()));
                        }

                        if (!mounted) return;

                        // ✅ Pop THEN navigate — both using parentContext
                        Navigator.of(parentContext).pop();

                        if (hasProfile) {
                          parentContext.safeGoNamed(home);
                        } else {
                          parentContext.safeGoNamed(
                            clientProfile,
                            params: {
                              'clientId': obtainedClientId,
                              'deviceToken': token ?? '',
                            },
                          );
                        }
                      }

                      if (state is VerifyOtpError) {
                        _shakeController
                            .forward()
                            .then((_) => _shakeController.reverse());
                        showErrorAlert(state.message, parentContext);
                      }
                    },
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _AppColors.gradientRide,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            onPressed: state is VerifyOtpLoading
                                ? null
                                : () {
                                    if (otpController.text.length != 6) {
                                      showErrorAlert(
                                        'Enter a valid OTP',
                                        context,
                                      );
                                      return;
                                    }

                                    // Referral code is optional — only
                                    // sent along if the client filled it in.
                                    final referral =
                                        _referralCodeController.text.trim();

                                    verifyOtpBloc.add(
                                      HandleVerifyOtp(
                                        phone:
                                            phoneNumber!.replaceAll(' ', ''),
                                        otp: otpController.text,
                                        referralCode:
                                            referral.isEmpty ? null : referral,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                            ),
                            child: state is VerifyOtpLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Verify OTP',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    countdownTimer?.cancel();
    _referralCodeController.clear(); // NEW — reset for next open
  });
}

  Widget _buildBackdropOrb({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (phoneNumber.toString().length < 9 ||
              _phoneNumberController.text.isEmpty) {
            showErrorAlert('Please enter valid phone number', context);
          } else {
            _showPhoneConfirmationDialog(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isRegisterLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: whiteColor,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: _AppColors.bg,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _AppColors.bg,
                      _AppColors.bg2,
                    ]),
              ),
            ),
            _buildBackdropOrb(
              alignment: const Alignment(-1.15, -0.95),
              size: size.width * 0.78,
              color: primaryColor.withOpacity(0.12),
            ),
            _buildBackdropOrb(
              alignment: const Alignment(1.15, -0.55),
              size: size.width * 0.62,
              color: blueColor.withOpacity(0.1),
            ),
            _buildBackdropOrb(
              alignment: const Alignment(0.95, 1.1),
              size: size.width * 0.76,
              color: orangeColor.withOpacity(0.12),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child:
                        BlocConsumer<RegisterClientBloc, RegisterClientState>(
                      listener: (context, state) {
                        if (state is RegisterClientError) {
                          showErrorAlert(state.message, context);
                          setState(() {
                            isRegisterLoading = false;
                          });
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.remove('pendingVerification');
                          });
                        }
                        if (state is RegisterClientLoading) {
                          setState(() {
                            isRegisterLoading = true;
                          });
                        }
                        if (state is RegisterClientSuccess) {
                          setState(() {
                            isRegisterLoading = false;
                          });
                          _showOtpVerificationBottomSheet(context);
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verify your phone number',
                                        style: GoogleFonts.poppins(
                                          fontSize: 30,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Enter your mobile number to receive a one-time verification code.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          height: 1.6,
                                          color:
                                              _AppColors.txt2.withOpacity(0.62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (size.width > 420) ...[
                                  const SizedBox(width: 18),
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _AppColors.accent,
                                            _AppColors.accent.withOpacity(0.72),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _AppColors.accent
                                                .withOpacity(0.24),
                                            blurRadius: 28,
                                            offset: const Offset(0, 14),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/images/verified.png',
                                        width: 72,
                                        height: 72,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 150.ms, duration: 500.ms)
                                      .scale(
                                        begin: const Offset(0.7, 0.7),
                                        curve: Curves.elasticOut,
                                      ),
                                ],
                              ],
                            )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 450.ms)
                                .slideY(begin: 0.08, end: 0),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: whiteColor.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _AppColors.border.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _AppColors.accent.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _AppColors.border
                                                .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            Icons.phone_iphone_rounded,
                                            color: _AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mobile number',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Use a number you can access right now.',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  height: 1.55,
                                                  color: blackColor
                                                      .withOpacity(0.62),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    InternationalPhoneNumberInput(
                                      height: 60,
                                      controller: _phoneNumberController,
                                      initCountry: CountryCodeModel(
                                        name: 'Tanzania',
                                        dial_code: '+255',
                                        code: 'TZ',
                                      ),
                                      betweenPadding: 12,
                                      onInputChanged: (phone) {
                                        setState(() {
                                          countryCode = phone.code;
                                          phoneNumber =
                                              phone.rawFullNumber.toString();
                                        });
                                      },
                                      loadFromJson: loadFromJson,
                                      dialogConfig: DialogConfig(
                                        backgroundColor:
                                            const Color(0xFF444448),
                                        searchBoxBackgroundColor:
                                            const Color(0xFF56565a),
                                        searchBoxIconColor:
                                            const Color(0xFFFAFAFA),
                                        countryItemHeight: 50,
                                        flatFlag: true,
                                        topBarColor: const Color(0xFF1B1C24),
                                        selectedItemColor:
                                            const Color(0xFF56565a),
                                        selectedIcon: const Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        textStyle: GoogleFonts.poppins(
                                          color: const Color(0xFFFAFAFA)
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        searchBoxTextStyle: GoogleFonts.poppins(
                                          color: const Color(0xFFFAFAFA)
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        titleStyle: GoogleFonts.poppins(
                                          color: const Color(0xFFFAFAFA),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        searchBoxHintStyle: GoogleFonts.poppins(
                                          color: const Color(0xFFFAFAFA)
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      countryConfig: CountryConfig(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.grey[50],
                                          border: Border.all(
                                            width: 1.5,
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        flatFlag: true,
                                        noFlag: false,
                                        flagSize: 28,
                                        textStyle: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      validator: (number) {
                                        if (number.number.isEmpty) {
                                          return 'The phone number cannot be left empty';
                                        }
                                        return null;
                                      },
                                      phoneConfig: PhoneConfig(
                                        focusedColor: primaryColor,
                                        enabledColor: Colors.grey[300]!,
                                        errorColor: redColor,
                                        labelStyle: null,
                                        labelText: null,
                                        floatingLabelStyle: null,
                                        focusNode: null,
                                        radius: 12,
                                        hintText: 'xxx xxx xxx xxx',
                                        borderWidth: 1.5,
                                        backgroundColor: Colors.grey[50],
                                        decoration: null,
                                        popUpErrorText: true,
                                        autoFocus: false,
                                        showCursor: true,
                                        textInputAction: TextInputAction.done,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        errorTextMaxLength: 2,
                                        errorPadding:
                                            const EdgeInsets.only(top: 14),
                                        errorStyle: GoogleFonts.poppins(
                                          color: const Color(0xFFFF5494),
                                          fontSize: 12,
                                          height: 1,
                                        ),
                                        textStyle: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.black.withOpacity(0.4),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.10),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            color: primaryColor,
                                            size: 24,
                                          )
                                              .animate(
                                                onPlay: (controller) =>
                                                    controller.repeat(),
                                              )
                                              .shimmer(
                                                delay: 2000.ms,
                                                duration: 2000.ms,
                                              ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Privacy & consent',
                                                  style: GoogleFonts.poppins(
                                                    color: primaryColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'By signing up, you agree to our Terms of Service and Privacy Policy.',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12,
                                                    height: 1.55,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 320.ms, duration: 500.ms)
                                .slideY(begin: 0.08, end: 0),
                            const SizedBox(height: 22),
                            _buildPrimaryAction()
                                .animate()
                                .fadeIn(delay: 520.ms, duration: 500.ms)
                                .slideY(begin: 0.08, end: 0),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
