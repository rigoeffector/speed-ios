import 'package:firebase_core/firebase_core.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/api/firebase.notification.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/states/register.client/register_client_bloc.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:intl_phone_number_field/intl_phone_number_field.dart';

import '../../../utils/colors.dart';
import '../../widgets/heading.dart';

class VerifyPhoneNumber extends StatefulWidget {
  const VerifyPhoneNumber({Key? key}) : super(key: key);

  @override
  State<VerifyPhoneNumber> createState() => _VerifyPhoneNumberState();
}

class _VerifyPhoneNumberState extends State<VerifyPhoneNumber> {
  RegisterClientBloc registerClientBloc =
      RegisterClientBloc(RegisterClientInitial(), AuthService());
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String sentOtp = "";
  String? token;
  bool isRegisterLoading = false;
  // FirebaseMessaging? _firebaseMessaging;
  // FirebaseFirestore? _firestore;
  // FirebaseApi firebaseApi = FirebaseApi();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _initializeFirebase();
  }

  // Future<void> _initializeFirebase() async {
  //   // Ensure Firebase is initialized before using its services
  //   if (Firebase.apps.isEmpty) {
  //     await Firebase.initializeApp();
  //   }

  //   setState(() {
  //     _firebaseMessaging = FirebaseMessaging.instance;
  //     _firestore = FirebaseFirestore.instance;
  //   });

  //   loadFromJson();
  //   getToken();
  //   registerClientBloc = BlocProvider.of<RegisterClientBloc>(context);
  // }

  String? countryCode, phoneNUmber;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  // void getToken() async {
  //   if (_firebaseMessaging == null) return;

  //   await _firebaseMessaging!.requestPermission();
  //   final fcmToken = await _firebaseMessaging!.getToken();

  //   token = fcmToken;
  //   if (kDebugMode) {
  //     print("MyToken $token");
  //   }
  // }

  void saveTokenDevice(String userId, String token) async {
    // if (_firestore == null) return;
    // saveToken(token.toString(), userId);
  }

  void saveToken(String token, String userId) async {
    // if (_firestore == null) return;
    // await _firestore!
    //     .collection('clientTokens')
    //     .doc(userId)
    //     .set({'token': token});
  }

  Future<String> loadFromJson() async {
    return await rootBundle.loadString('assets/countries/country_list.json');
  }

  TextEditingController controller = TextEditingController();
  String? data;
  final RegExp maskRegExp = RegExp(r'^\d{3} \d{3} \d{3}$');

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: whiteColor,
        body: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Image.asset(
                      "assets/images/verified.png",
                      scale: 3,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Heading(
                      title: 'Phone verification'.tr(),
                      subtitle:
                          'Please enter you phone number in field bellow'.tr(),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.transparent),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8.0)),
                      ),
                      child: Form(
                        key: formKey,
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              InternationalPhoneNumberInput(
                                height: 55,
                                controller: _phoneNumberController,
                                inputFormatters: const [],
                                formatter: MaskedInputFormatter('### ### ###'),
                                initCountry: CountryCodeModel(
                                    name: "Rwanda",
                                    dial_code: "+250",
                                    code: "RW"),
                                betweenPadding: 4,
                                onInputChanged: (phone) {
                                  print(phone.code);
                                  print(phone.dial_code);
                                  print(phone.number);
                                  print(phone.rawFullNumber);
                                  print(phone.rawNumber);
                                  print(phone.rawDialCode);

                                  setState(() {
                                    countryCode = phone.code.toString();
                                    phoneNUmber =
                                        phone.rawFullNumber.toString();
                                  });
                                },
                                loadFromJson: loadFromJson,
                                dialogConfig: DialogConfig(
                                  backgroundColor: const Color(0xFF444448),
                                  searchBoxBackgroundColor:
                                      const Color(0xFF56565a),
                                  searchBoxIconColor: const Color(0xFFFAFAFA),
                                  countryItemHeight: 40,
                                  flatFlag: true,
                                  topBarColor: const Color(0xFF1B1C24),
                                  selectedItemColor: const Color(0xFF56565a),
                                  selectedIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(Icons.check_circle_outline),
                                  ),
                                  textStyle: TextStyle(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  searchBoxTextStyle: TextStyle(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  titleStyle: const TextStyle(
                                      color: Color(0xFFFAFAFA),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                  searchBoxHintStyle: TextStyle(
                                      color: const Color(0xFFFAFAFA)
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                countryConfig: CountryConfig(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: whiteColor1,
                                        border: Border.all(
                                            width: 1,
                                            color: Colors.transparent)),
                                    flatFlag: true,
                                    noFlag: false,
                                    flagSize: 25,
                                    textStyle: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400)),
                                validator: (number) {
                                  if (number.number.isEmpty) {
                                    return "The phone number cannot be left empty";
                                  }

                                  return null;
                                },
                                phoneConfig: PhoneConfig(
                                  focusedColor: primaryColor,
                                  enabledColor: greyColor1,
                                  autoFocus: true,
                                  errorColor: redColor,
                                  labelStyle: null,
                                  labelText: null,
                                  floatingLabelStyle: null,
                                  focusNode: null,
                                  radius: 8,
                                  hintText: "eg: (+250) 000 000 000",
                                  borderWidth: 1,
                                  backgroundColor: Colors.transparent,
                                  decoration: null,
                                  popUpErrorText: true,
                                  showCursor: false,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  errorTextMaxLength: 2,
                                  errorPadding: const EdgeInsets.only(top: 14),
                                  errorStyle: const TextStyle(
                                      color: Color(0xFFFF5494),
                                      fontSize: 12,
                                      height: 1),
                                  textStyle: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                  hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                              Visibility(
                                visible: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: primaryColor,
                                        size: 25,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "If you already have account in our system  ",
                                              style: GoogleFonts.rubik(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 13),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Login into account",
                                                  style: GoogleFonts.rubik(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontSize: 13),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: BlocConsumer<RegisterClientBloc, RegisterClientState>(
                    listener: (context, state) {
                      if (state is RegisterClientError) {
                        showErrorAlert(state.message, context);
                        setState(() {
                          isRegisterLoading = false;
                        });

                        String obtainedClientId =
                            state.registerClientModel.data!.first.id.toString();

                        saveTokenDevice(obtainedClientId, token.toString());

                        context.safeGoNamed(home);
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
                        // String obtainedOtp = "2023";
                        String obtainedFname = state
                            .registerClientModel.data!.first.fname
                            .toString();

                        String obtainedLname = state
                            .registerClientModel.data!.first.lname
                            .toString();

                        String obtainedClientId =
                            state.registerClientModel.data!.first.id.toString();

                        saveTokenDevice(obtainedClientId, token.toString());

                        if (obtainedFname != "null" &&
                            obtainedLname != "null") {
                          context.safeGoNamed(home);
                        } else {
                          context.safeGoNamed(clientProfile,
                              params: {'clientId': obtainedClientId});
                        }
                      }
                    },
                    builder: (context, state) {
                      return MyButton(
                        backgroundColor: primaryColor,
                        titleColor: whiteColor,
                        title: 'Continue',
                        onTap: () {
                          if (phoneNUmber.toString().length < 9 ||
                              _phoneNumberController.text.isEmpty) {
                            showErrorAlert(
                                "Please enter valid phone number", context);
                          } else {
                            registerClientBloc.add(
                                HandleRegisterClientInformation(
                                    phone: phoneNUmber.toString(),
                                    deviceToken: token.toString(),
                                    countryCode: countryCode.toString()));
                          }
                        },
                        isLoading: isRegisterLoading,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          height: 40,
          child: Center(
            child: Text(
              "Powerd by Besoft & BePay ltd",
              style: GoogleFonts.poppins(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
