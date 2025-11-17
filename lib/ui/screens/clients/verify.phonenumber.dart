import 'dart:async';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl_phone_number_field/intl_phone_number_field.dart';
import '../../../routes/routes.names.dart';
import '../../../states/register.client/register_client_bloc.dart';
import '../../../states/verify/verify_otp_bloc.dart';
import '../../../utils/colors.dart';
import '../../../utils/notifiers.dart';
import '../../widgets/buttons/button.dart';

class VerifyPhoneNumber extends StatefulWidget {
  const VerifyPhoneNumber({Key? key}) : super(key: key);

  @override
  State<VerifyPhoneNumber> createState() => _VerifyPhoneNumberState();
}

class _VerifyPhoneNumberState extends State<VerifyPhoneNumber>
    with TickerProviderStateMixin {
  late RegisterClientBloc registerClientBloc;
  late VerifyOtpBloc verifyOtpBloc;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? token;
  String? countryCode;
  String? phoneNumber;
  bool isRegisterLoading = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    registerClientBloc = BlocProvider.of<RegisterClientBloc>(context);
    verifyOtpBloc = BlocProvider.of<VerifyOtpBloc>(context);
    _initializeAnimations();
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

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<String> loadFromJson() async {
    return await rootBundle.loadString('assets/countries/country_list.json');
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
              color: whiteColor,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          side:
                              BorderSide(color: Colors.grey.shade300, width: 2),
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Send initial OTP request
                          // verifyOtpBloc.add(HandleResendOtp(
                          //   phone: phoneNumber!.replaceAll(' ', ''),
                          // ));
                          registerClientBloc.add(
                            HandleRegisterClientInformation(
                              phone: phoneNumber!,
                              deviceToken: token.toString(),
                              countryCode: countryCode.toString(),
                            ),
                          );
                          _showOtpVerificationBottomSheet(context);
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
            // Start countdown timer
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                top: 24.0,
                left: 24.0,
                right: 24.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 32),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: whiteColor,
                          size: 48,
                        ),
                      ),
                    )
                        .animate()
                        .scale(curve: Curves.elasticOut, duration: 600.ms),
                    const SizedBox(height: 24),
                    Text(
                      'OTP Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'We have sent a verification code to',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: blackColor.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        phoneNumber.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .shimmer(delay: 800.ms, duration: 1500.ms),
                    const SizedBox(height: 36),
                    Pinput(
                      length: 6,
                      controller: otpController,
                      defaultPinTheme: PinTheme(
                        width: 56,
                        height: 64,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(
                              color: Colors.grey.shade300, width: 2.0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 56,
                        height: 64,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          border: Border.all(color: primaryColor, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      errorPinTheme: PinTheme(
                        width: 56,
                        height: 64,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: redColor,
                        ),
                        decoration: BoxDecoration(
                          color: redColor.withOpacity(0.05),
                          border: Border.all(color: redColor, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (pin) {},
                      onCompleted: (pin) {},
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive the code?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: blackColor.withOpacity(0.6),
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
                              countdownTimer?.cancel();
                              countdownTimer = Timer.periodic(
                                const Duration(seconds: 1),
                                (timer) {
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
                                },
                              );
                            }
                            if (state is ResendOtpError) {
                              showErrorAlert(state.message, context);
                            }
                          },
                          builder: (context, state) {
                            return TextButton(
                              onPressed: (canResend &&
                                      state is! ResendOtpLoading)
                                  ? () {
                                      verifyOtpBloc.add(HandleResendOtp(
                                        phone: phoneNumber!.replaceAll(' ', ''),
                                      ));
                                    }
                                  : null,
                              child: state is ResendOtpLoading
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      canResend
                                          ? 'Resend'
                                          : 'Resend in ${resendTimer}s',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: canResend
                                            ? primaryColor
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 32),
                    BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
                      listener: (context, state) {
                        if (state is VerifyOtpSuccess) {
                          Navigator.pop(context);
                          countdownTimer?.cancel();

                          setState(() {
                            isRegisterLoading = true;
                          });

                          String obtainedFname =
                              state.verifyOtpModel.data!.fname.toString();
                          String obtainedLname =
                              state.verifyOtpModel.data!.lname.toString();
                          String obtainedClientId =
                              state.verifyOtpModel.data!.id.toString();
                          if (obtainedFname != "null" &&
                              obtainedLname != "null") {
                            context.safeGoNamed(home);
                          } else {
                            context.safeGoNamed(clientProfile,
                                params: {'clientId': obtainedClientId});
                          }
                        }
                        if (state is VerifyOtpError) {
                          _shakeController
                              .forward()
                              .then((_) => _shakeController.reverse());
                          showErrorAlert(state.message, context);
                        }
                      },
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: (state is! VerifyOtpLoading)
                                ? () {
                                    if (otpController.text.length < 6) {
                                      _shakeController.forward().then(
                                          (_) => _shakeController.reverse());
                                      showErrorAlert(
                                        'Please enter a valid 6-digit OTP code',
                                        context,
                                      );
                                      return;
                                    }
                                    verifyOtpBloc.add(HandleVerifyOtp(
                                      phone: phoneNumber!.replaceAll(' ', ''),
                                      otp: otpController.text,
                                    ));
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: state is VerifyOtpLoading ? 0 : 4,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: state is VerifyOtpLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: whiteColor,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Verify',
                                    style: GoogleFonts.poppins(
                                      color: whiteColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0)
                        .shimmer(delay: 1500.ms, duration: 2000.ms),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: whiteColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.02),
                whiteColor,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/verified.png",
                          scale: 3.5,
                          color: whiteColor,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                            begin: const Offset(0.6, 0.6),
                            curve: Curves.elasticOut)
                        .then(delay: 200.ms)
                        .shimmer(duration: 2000.ms),
                    const SizedBox(height: 40),
                    Text(
                      'Phone Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Please enter your phone number in the field below',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: blackColor.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: 50),
                    // Form(
                    //   key: formKey,
                    //   child: InternationalPhoneNumberInput(
                    //     height: 62,
                    //     controller: _phoneNumberController,
                    //     inputFormatters: const [],
                    //     formatter: MaskedInputFormatter('### ### ###'),
                    //     initCountry: CountryCodeModel(
                    //       name: "Rwanda",
                    //       dial_code: "+250",
                    //       code: "RW",
                    //     ),
                    //     betweenPadding: 12,
                    //     onInputChanged: (phone) {
                    //       setState(() {
                    //         countryCode = phone.code;
                    //         phoneNumber = phone.rawFullNumber.toString();
                    //       });
                    //     },
                    //     loadFromJson: loadFromJson,
                    //     dialogConfig: DialogConfig(
                    //       backgroundColor: const Color(0xFF444448),
                    //       searchBoxBackgroundColor: const Color(0xFF56565a),
                    //       searchBoxIconColor: const Color(0xFFFAFAFA),
                    //       countryItemHeight: 50,
                    //       flatFlag: true,
                    //       topBarColor: primaryColor,
                    //       selectedItemColor: const Color(0xFF56565a),
                    //       selectedIcon: const Padding(
                    //         padding: EdgeInsets.only(left: 10),
                    //         child:
                    //             Icon(Icons.check_circle, color: primaryColor),
                    //       ),
                    //       textStyle: GoogleFonts.poppins(
                    //         color: const Color(0xFFFAFAFA).withOpacity(0.7),
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //       searchBoxTextStyle: GoogleFonts.poppins(
                    //         color: const Color(0xFFFAFAFA).withOpacity(0.7),
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //       titleStyle: GoogleFonts.poppins(
                    //         color: const Color(0xFFFAFAFA),
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.w700,
                    //       ),
                    //       searchBoxHintStyle: GoogleFonts.poppins(
                    //         color: const Color(0xFFFAFAFA).withOpacity(0.7),
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //     countryConfig: CountryConfig(
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(16),
                    //         color: whiteColor,
                    //         border: Border.all(
                    //             width: 2, color: primaryColor.withOpacity(0.2)),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: primaryColor.withOpacity(0.05),
                    //             blurRadius: 10,
                    //             offset: const Offset(0, 4),
                    //           ),
                    //         ],
                    //       ),
                    //       flatFlag: true,
                    //       noFlag: false,
                    //       flagSize: 28,
                    //       textStyle: GoogleFonts.poppins(
                    //         color: primaryColor,
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //     validator: (number) {
                    //       if (number.number.isEmpty) {
                    //         return "The phone number cannot be left empty";
                    //       }
                    //       return null;
                    //     },
                    //     phoneConfig: PhoneConfig(
                    //       focusedColor: primaryColor,
                    //       enabledColor: Colors.grey.shade300,
                    //       autoFocus: true,
                    //       errorColor: redColor,
                    //       labelStyle: null,
                    //       labelText: null,
                    //       floatingLabelStyle: null,
                    //       focusNode: null,
                    //       radius: 16,
                    //       hintText: "eg: (+250) 000 000 000",
                    //       borderWidth: 2,
                    //       backgroundColor: Colors.transparent,
                    //       decoration: null,
                    //       popUpErrorText: true,
                    //       showCursor: true,
                    //       textInputAction: TextInputAction.done,
                    //       autovalidateMode: AutovalidateMode.onUserInteraction,
                    //       errorTextMaxLength: 2,
                    //       errorPadding: const EdgeInsets.only(top: 14),
                    //       errorStyle: GoogleFonts.poppins(
                    //         color: redColor,
                    //         fontSize: 12,
                    //         height: 1,
                    //       ),
                    //       textStyle: GoogleFonts.poppins(
                    //         color: primaryColor,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //       hintStyle: GoogleFonts.poppins(
                    //         color: Colors.black.withOpacity(0.4),
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w400,
                    //       ),
                    //     ),
                    //   ),
                    // )
                    //     .animate()
                    //     .fadeIn(delay: 500.ms, duration: 600.ms)
                    //     .slideX(begin: -0.2, end: 0),
                    // Phone Input Form
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              InternationalPhoneNumberInput(
                                height: 60,
                                controller: _phoneNumberController,
                                // inputFormatters: const [],
                                // formatter: MaskedInputFormatter('### ### ###'),
                                initCountry: CountryCodeModel(
                                    name: "Rwanda",
                                    dial_code: "+250",
                                    code: "RW"),
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
                                  backgroundColor: const Color(0xFF444448),
                                  searchBoxBackgroundColor:
                                      const Color(0xFF56565a),
                                  searchBoxIconColor: const Color(0xFFFAFAFA),
                                  countryItemHeight: 50,
                                  flatFlag: true,
                                  topBarColor: const Color(0xFF1B1C24),
                                  selectedItemColor: const Color(0xFF56565a),
                                  selectedIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(Icons.check_circle,
                                        color: Colors.greenAccent),
                                  ),
                                  textStyle: GoogleFonts.poppins(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  searchBoxTextStyle: GoogleFonts.poppins(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  titleStyle: GoogleFonts.poppins(
                                      color: const Color(0xFFFAFAFA),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                  searchBoxHintStyle: GoogleFonts.poppins(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                countryConfig: CountryConfig(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[50],
                                        border: Border.all(
                                            width: 1.5,
                                            color: Colors.grey[300]!)),
                                    flatFlag: true,
                                    noFlag: false,
                                    flagSize: 28,
                                    textStyle: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                validator: (number) {
                                  if (number.number.isEmpty) {
                                    return "The phone number cannot be left empty";
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
                                  hintText: "xxx xxx xxx xxx",
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
                                  errorPadding: const EdgeInsets.only(top: 14),
                                  errorStyle: GoogleFonts.poppins(
                                      color: const Color(0xFFFF5494),
                                      fontSize: 12,
                                      height: 1),
                                  textStyle: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                  hintStyle: GoogleFonts.poppins(
                                      color: Colors.black.withOpacity(0.4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Terms and Conditions
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: primaryColor,
                                      size: 28,
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat())
                                        .shimmer(
                                            delay: 2000.ms, duration: 2000.ms),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "By signing up, you agree to our",
                                            style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              Text(
                                                "Terms of Service",
                                                style: GoogleFonts.poppins(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                              Text(
                                                "and",
                                                style: GoogleFonts.poppins(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12),
                                              ),
                                              Text(
                                                "Privacy Policy",
                                                style: GoogleFonts.poppins(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 50),
                    BlocConsumer<RegisterClientBloc, RegisterClientState>(
                      listener: (context, state) {
                        if (state is RegisterClientError) {
                          showErrorAlert(state.message, context);
                          setState(() {
                            isRegisterLoading = false;
                          });
                          if (state.registerClientModel.data != null &&
                              state.registerClientModel.data!.isNotEmpty) {
                            String obtainedClientId = state
                                .registerClientModel.data!.first.id
                                .toString();
                            context.safeGoNamed(home);
                          }
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
                        return MyButton(
                          backgroundColor: primaryColor,
                          titleColor: whiteColor,
                          title: 'Continue',
                          onTap: () {
                            if (phoneNumber.toString().length < 9 ||
                                _phoneNumberController.text.isEmpty) {
                              showErrorAlert(
                                  "Please enter valid phone number", context);
                            } else {
                              _showPhoneConfirmationDialog(context);
                            }
                          },
                          isLoading: isRegisterLoading,
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0);
                      },
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
}
