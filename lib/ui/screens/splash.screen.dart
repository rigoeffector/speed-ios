import 'dart:async';
import 'dart:convert';

import 'package:speed_ios/model/auth/register.client.model.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _animations;
  late ClientData user;
  var json;
  String? jsonCheck, jsonCode, jsonCheckProfile, token;
  @override
  void initState() {
    super.initState();
    user = ClientData();
    // startTime();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Create the animations
    _animations = List.generate(
      Strings.appName.length,
      (index) {
        final startPosition = Offset(
          (index - Strings.appName.length / 2) * 48.0 + 24.0,
          0,
        );
        final endPosition = Offset.zero;
        return Tween<Offset>(
          begin: startPosition,
          end: endPosition,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
      },
    );

    // Start the animation
    _animationController.forward().whenComplete(() {
      startTime();
    });
  }

  startTime() async {
    final prefs = await SharedPreferences.getInstance();
    json = prefs.getString('currentUser') ?? 'no';
    jsonCheck = prefs.getString('currentUser') ?? 'no';
    jsonCheckProfile = prefs.getString('currentUserProfile') ?? 'no';
    jsonCode = prefs.getString('currentCountryCode') ?? 'no';
    var duration = const Duration(milliseconds: 100);

    if (jsonCheck == 'no') {
      return Timer(duration, navigationPage);
    } else {
      Map<String, dynamic> map = jsonDecode(json);
      user = ClientData.fromJson(map);
      if (kDebugMode) {
        print("USER $json");
      }
      var duration = const Duration(seconds: 2);
      return Timer(duration, navigationPage);
    }
  }

  void navigationPage() {
    // Check conditions in sequence
    if (jsonCheck == 'no') {
      context.safeGoNamed(verify);
    } else if (jsonCheckProfile == 'no') {
      context
          .safeGoNamed(clientProfile, params: {'clientId': user.id.toString()});
    } else {
      context.safeGoNamed(home, params: {
        'userId': user.id.toString(),
        'countryCode': jsonCode.toString()
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double bottomPaddingPercentage = 0.1;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double bottomPadding = screenHeight * bottomPaddingPercentage;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Center(
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    Strings.appName.length,
                    (index) => Opacity(
                      opacity: 0,
                      child: Text(
                        Strings.appName[index],
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: orangeColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    Strings.appName.length,
                    (index) => SlideTransition(
                      position: _animations[index],
                      child: Text(
                        Strings.appName[index],
                        style: GoogleFonts.poppins(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: whiteColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: primaryColor,
        height: 40,
        child: Center(
          child: Text(
            "Powerd by Besoft & BePay ltd",
            style: GoogleFonts.poppins(fontSize: 12, color: whiteColor),
          ),
        ),
      ),
    );
  }
}
