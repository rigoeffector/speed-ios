import 'dart:async';

import 'package:speed_ios/controllers/home_controller.dart';
import 'package:speed_ios/ui/screens/clients/verify.phonenumber.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/ui/widgets/forms/email_text_input.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:speed_ios/utils/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordClient extends StatefulWidget {
  const ForgotPasswordClient({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordClient> createState() => _ForgotPasswordClientState();
}

class _ForgotPasswordClientState extends State<ForgotPasswordClient> {
  final controller = HomeController();
  void _onSelectCity() {
    controller.changeHomeState(HomeState.selectCity);
  }

  TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/back.jpg"),
                    fit: BoxFit.cover)),
          ),
          Positioned(
              child: Container(
            color: primaryColorOverlay,
          )),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "app_txt_car".tr(),
                        style: GoogleFonts.poppins(
                            color: whiteColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "app_txt_nayo".tr(),
                        style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Text(
                      "app_txt_forgot_your_password".tr(),
                      style: GoogleFonts.poppins(
                          color: blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: Form(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            child: Text(
                              "app_txt_forgot_your_password".tr(),
                              style: GoogleFonts.poppins(
                                  color: blackColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor1,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  child: const Center(
                                    child: Icon(
                                      Icons.call,
                                      color: whiteColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                      width: 220,
                                      child: Text(
                                        "Login with your mobile number",
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: whiteColor,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 13),
                                      )),
                                )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                color: whiteColor1,
                                height: 1,
                                width: 100,
                              ),
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("OR"),
                              ),
                              Container(
                                color: whiteColor1,
                                height: 1,
                                width: 100,
                              ),
                            ],
                          ),
                          TextInputFieldEmailaAddress(
                              emailController, "Email address"),
                          MyButton(
                              title: 'app_txt_login'.tr(),
                              titleColor: primaryColor,
                              backgroundColor: blackColor,
                              onTap: () {
                                setState(() {
                                  isLoading = true;
                                });
                                Timer(const Duration(milliseconds: 800), () {
                                  setState(() {
                                    isLoading = false;
                                  });
                                });
                              },
                              isLoading: isLoading),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MyPageRoute(widget: VerifyPhoneNumber()),
                              );
                            },
                            child: Text(
                              "Back To Login".tr(),
                              style: GoogleFonts.poppins(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
