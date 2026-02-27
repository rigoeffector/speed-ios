import 'dart:async';
import 'dart:convert';

import 'package:speed_ios/model/auth/register.client.model.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/constants.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
    final _firebaseMessaging = FirebaseMessaging.instance;

  late ClientData user;
  var json;
  String? jsonCheck, jsonCode, jsonCheckProfile, token;
  
  @override
  void initState() {
    super.initState();
    user = ClientData();
    getToken();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Delay before starting navigation
    Future.delayed(const Duration(milliseconds: 3000), () {
      startTime();
    });
  }

    void getToken() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getAPNSToken();

    token = fcmToken;
    if (kDebugMode) {
      print("MyToken $token");
    }
  }

void navigationPage() {
  // Guard: ensure widget is still mounted
  if (!mounted) return;

  final bool hasUser = jsonCheck != null && jsonCheck != 'no';
  final bool hasProfile = jsonCheckProfile != null && jsonCheckProfile != 'no';
  final bool hasToken = token != null && token!.isNotEmpty;

  if (!hasUser) {
    // No account found → go to verify/register
    context.safeGoNamed(verify, params: {
      'deviceToken': hasToken ? token! : '',
    });
    return;
  }

  // Validate stored user data is parseable
  try {
    final Map<String, dynamic> map = jsonDecode(json);
    user = ClientData.fromJson(map);

    final String userId = user.id?.toString() ?? '';
    if (userId.isEmpty) {
      // Corrupt user data → clear and restart
      _clearAndRestart();
      return;
    }

    if (!hasProfile) {
      // Account exists but profile incomplete
      context.safeGoNamed(clientProfile, params: {
        'clientId': userId,
        'deviceToken': hasToken ? token! : '',
      });
      return;
    }

    // Fully authenticated → go home
    context.safeGoNamed(home, params: {
      'userId': userId,
      'countryCode': (jsonCode != null && jsonCode != 'no') ? jsonCode! : 'rw',
      'token': hasToken ? token! : '',
    });

  } catch (e) {
    if (kDebugMode) print('Navigation error - corrupt data: $e');
    _clearAndRestart();
  }
}

Future<void> _clearAndRestart() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!mounted) return;
  context.safeGoNamed(verify, params: {
    'deviceToken': token ?? '',
  });
}

Future<void> startTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    json           = prefs.getString('currentUser')        ?? 'no';
    jsonCheck      = prefs.getString('currentUser')        ?? 'no';
    jsonCheckProfile = prefs.getString('currentUserProfile') ?? 'no';
    jsonCode       = prefs.getString('currentCountryCode') ?? 'no';

    if (!mounted) return;

    // Short delay so splash animation completes
    await Future.delayed(
      jsonCheck == 'no'
          ? const Duration(milliseconds: 100)
          : const Duration(seconds: 2),
    );

    if (!mounted) return;
    navigationPage();

  } catch (e) {
    if (kDebugMode) print('startTime error: $e');
    if (!mounted) return;
    await _clearAndRestart();
  }
}

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 3000.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
                .then()
                .scale(duration: 3000.ms, begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 4000.ms, begin: const Offset(1, 1), end: const Offset(1.3, 1.3))
                .then()
                .scale(duration: 4000.ms, begin: const Offset(1.3, 1.3), end: const Offset(1, 1)),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated logo container
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      size: 80,
                      color: Colors.amber,
                    ),
                  )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                    )
                    .then(delay: 200.ms)
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3))
                    .then()
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      duration: 2000.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                    )
                    .then()
                    .scale(
                      duration: 2000.ms,
                      begin: const Offset(1.05, 1.05),
                      end: const Offset(1, 1),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // App name with staggered animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: Strings.appName.split('').asMap().entries.map((entry) {
                      int index = entry.key;
                      String char = entry.value;
                      return Text(
                        char,
                        style: GoogleFonts.poppins(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: whiteColor,
                          height: 1.2,
                        ),
                      )
                        .animate()
                        .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                        .slideY(
                          begin: -0.5,
                          end: 0,
                          delay: (100 * index).ms,
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then(delay: 500.ms)
                        .shimmer(duration: 1500.ms, color: Colors.amber.withOpacity(0.5));
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle with gradient effect
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.yellow,
                        Colors.yellow.shade700,
                        Colors.yellowAccent,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      "Speed Ride Sharing – Safe Rides, Peaceful Journeys",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, delay: 800.ms, duration: 600.ms)
                    .then(delay: 400.ms)
                    .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.6)),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 4,
                      ),
                    ),
                  )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(delay: 1200.ms, duration: 600.ms)
                    .shimmer(
                      delay: 1800.ms,
                      duration: 1500.ms,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Loading text
                  Text(
                    "Loading...",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(delay: 1400.ms, duration: 600.ms)
                    .then()
                    .fade(duration: 1000.ms, begin: 1, end: 0.5)
                    .then()
                    .fade(duration: 1000.ms, begin: 0.5, end: 1),
                ],
              ),
            ),
            
            // Bottom branding
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Decorative line
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.amber.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 1600.ms, duration: 800.ms)
                    .scale(begin: const Offset(0, 1), end: const Offset(1, 1)),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "Powered by Besoft & BePay ltd",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  )
                    .animate()
                    .fadeIn(delay: 1800.ms, duration: 800.ms)
                    .slideY(begin: 0.5, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}