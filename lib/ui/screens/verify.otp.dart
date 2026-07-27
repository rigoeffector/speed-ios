import 'package:speed_ios/routes/routes.provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import '../widgets/buttons/button.dart';
import '../widgets/heading.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String? type;
  final String? otp;
  final String? phone;
  final String? clientId;
  const VerifyOtpScreen(
      {Key? key, this.type, this.otp, this.phone, this.clientId})
      : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  String? userId, countryCode;
  final formKey = GlobalKey<FormState>();
 

  @override
  void initState() {
    userId = widget.clientId.toString();
    // sendNotification();
    loadCountryCode();
    super.initState();
  }



  String? jsonCode;
  loadCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    jsonCode = prefs.getString('currentCountryCode') ?? 'no';

    setState(() {
      countryCode = jsonCode;
    });
    print("COUNTRY CODE $jsonCode");
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Color.fromRGBO(16, 151, 72, 1.0);
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(119, 141, 169, 0.6901960784313725);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.4),
      ),
    );
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
            child: Stack(
          children: [
            Scaffold(
              backgroundColor: whiteColor,
              appBar: AppBar(
                backgroundColor: whiteColor,
                elevation: 0,
                toolbarHeight: 70,
                leading: InkWell(
                    onTap: () {
                      context.safeGoNamed(verify);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: primaryColor,
                    )),
              ),
              body: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Image.asset(
                        "assets/images/yes.png",
                        scale: 3,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Heading(
                        title: ' Verification code'.tr(),
                        subtitle:
                            'Your verification code has been sent to phone number bellow'
                                .tr(),
                      ),
                      Text(
                        "${widget.phone}",
                        style: GoogleFonts.rubik(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 18),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 35),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Pinput(
                                controller: pinController,
                                focusNode: focusNode,
                                defaultPinTheme: defaultPinTheme,
                                validator: (value) {
                                  return value == widget.otp
                                      ? null
                                      : 'Invalid code'.tr();
                                },
                                hapticFeedbackType:
                                    HapticFeedbackType.lightImpact,
                                onCompleted: (pin) {
                                  debugPrint('onCompleted: $pin');
                                  if (pin.toString() == widget.otp) {
                                    setState(() {});
                                  }
                                },
                                onChanged: (value) {
                                  debugPrint('onChanged: $value');
                                },
                                cursor: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 9),
                                      width: 22,
                                      height: 2,
                                      color: focusedBorderColor,
                                    ),
                                  ],
                                ),
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration:
                                      defaultPinTheme.decoration!.copyWith(
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: focusedBorderColor),
                                  ),
                                ),
                                submittedPinTheme: defaultPinTheme.copyWith(
                                  decoration:
                                      defaultPinTheme.decoration!.copyWith(
                                    color: fillColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: focusedBorderColor),
                                  ),
                                ),
                                errorPinTheme: defaultPinTheme.copyBorderWith(
                                  border: Border.all(color: Colors.redAccent),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            TextButton(
                                onPressed: () {
                                  // sendNotification();
                                },
                                child: Text(
                                  "Resend code".tr(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextButton(onPressed: () {}, child: Text(""))
                    ],
                  ),
                ),
              ),
              bottomSheet: Container(
                color: whiteColor,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                  child: MyButton(
                    backgroundColor: primaryColor,
                    titleColor: whiteColor,
                    title: 'Continue'.tr(),
                    isLoading: false,
                    onTap: () {
                      // 1:
                      if (widget.type == "2") {
                        context.safeGoNamed(clientProfile,
                            params: {'clientId': widget.clientId.toString()});
                      } else {
                        context.safeGoNamed(home, params: {
                          'userId': widget.clientId.toString(),
                          'countryCode': countryCode.toString()
                        });
                      }
                      // settingUpDashboard();
                    },
                  ),
                ),
              ),
            ),
            // Visibility(
            //   visible: _isSettingDashboard,
            //   child: Positioned(
            //       child: Column(
            //     children: [
            //       Container(
            //         width: MediaQuery.of(context).size.width,
            //         height: MediaQuery.of(context).size.height,
            //         color: primaryColorOverlay1,
            //         child: const Center(
            //           child: SpinKitFadingCube(
            //             color: whiteColor,
            //             size: 50,
            //           ),
            //         ),
            //       )
            //     ],
            //   )),
            // ),
          ],
        )));
  }
}
