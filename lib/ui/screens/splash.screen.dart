import 'dart:async';
import 'dart:convert';

import 'package:speed_ios/model/auth/register.client.model.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../utils/constants.dart';

class _AppColors {
  static const bg = Color(0xFF081B17);
  static const bg2 = Color(0xFF102520);
  static const bg3 = Color(0xFF16332C);
  static const bg4 = Color(0xFF1C4138);
  static const accent = Color(0xFF16A34A);
  static const accent2 = Color(0xFF0F766E);
  static const txt = Color(0xFFF8FAFC);
  static const txt2 = Color(0xFFCBD5E1);
  static const txt3 = Color(0xFF94A3B8);
  static const gradientRide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF0F766E)],
  );
}

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

  String? jsonCheck;
  String? jsonCode;
  String? jsonCheckProfile;
  String? token;
  String? jsonPendingVerification;

  @override
  void initState() {
    super.initState();
    user = ClientData();
    _loadTokenInBackground();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bootstrap();
  }

  Future<void> _loadTokenInBackground() async {
    try {
      final fcmToken = await _firebaseMessaging
          .getToken()
          .timeout(const Duration(milliseconds: 900));
      token = fcmToken;
      if (kDebugMode) print('MyToken $token');
    } catch (e) {
      if (kDebugMode) print('FCM token unavailable during splash: $e');
    }
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        _loadLaunchState(),
        Future<void>.delayed(const Duration(milliseconds: 2200)),
      ]);
      if (!mounted) return;
      navigationPage();
    } catch (e) {
      if (kDebugMode) print('bootstrap error: $e');
      if (!mounted) return;
      await _clearAndRestart();
    }
  }

  void navigationPage() {
    if (!mounted) return;

    final bool hasUser = jsonCheck != null && jsonCheck != 'no';
    final bool hasProfile = jsonCheckProfile != null && jsonCheckProfile != 'no';
    final bool hasToken = token != null && token!.isNotEmpty;
    final bool isPendingVerification =
        jsonPendingVerification != null && jsonPendingVerification != 'no';

    if (!hasUser || isPendingVerification) {
      context.safeGoNamed(verify, params: {
        'deviceToken': hasToken ? token! : '',
      });
      return;
    }

    try {
      final Map<String, dynamic> map = jsonDecode(json);
      user = ClientData.fromJson(map);
      final String userId = user.id?.toString() ?? '';
      if (userId.isEmpty) { _clearAndRestart(); return; }

      if (!hasProfile) {
        context.safeGoNamed(clientProfile, params: {
          'clientId': userId,
          'deviceToken': hasToken ? token! : '',
        });
        return;
      }

      context.safeGoNamed(home, params: {
        'userId': userId,
        'countryCode': (jsonCode != null && jsonCode != 'no') ? jsonCode! : 'rw',
        'token': hasToken ? token! : '',
      });
    } catch (e) {
      if (kDebugMode) print('Navigation error: $e');
      _clearAndRestart();
    }
  }

  Future<void> _clearAndRestart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.safeGoNamed(verify, params: {'deviceToken': token ?? ''});
  }

  Future<void> _loadLaunchState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser') ?? 'no';
    json = currentUser;
    jsonCheck = currentUser;
    jsonCheckProfile = prefs.getString('currentUserProfile') ?? 'no';
    jsonCode = prefs.getString('currentCountryCode') ?? 'no';
    jsonPendingVerification = prefs.getString('pendingVerification') ?? 'no';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: Stack(
        children: [
          // ── Background gradient wash ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_AppColors.bg, _AppColors.bg2, _AppColors.bg],
              ),
            ),
          ),

          // ── Orb — top right ──────────────────────────────────────────
          Positioned(
            top: -size.width * 0.28,
            right: -size.width * 0.18,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Opacity(
                opacity: 0.18 + _pulseController.value * 0.10,
                child: Container(
                  width: size.width * 0.72,
                  height: size.width * 0.72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_AppColors.accent, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Orb — bottom left ────────────────────────────────────────
          Positioned(
            bottom: -size.width * 0.32,
            left: -size.width * 0.22,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Opacity(
                opacity: 0.14 + _pulseController.value * 0.08,
                child: Container(
                  width: size.width * 0.80,
                  height: size.width * 0.80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_AppColors.accent2, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Subtle grid lines ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo mark
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 + _pulseController.value * 0.025,
                      child: child,
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_AppColors.accent, _AppColors.accent2],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _AppColors.accent.withOpacity(0.40),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: _AppColors.accent2.withOpacity(0.20),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.75, 0.75),
                        curve: Curves.elasticOut,
                        duration: 800.ms,
                      ),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                    Strings.appName,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _AppColors.txt,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 400.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 10),

                  // Tagline with gradient shimmer
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_AppColors.accent, _AppColors.accent2],
                    ).createShader(bounds),
                    child: Text(
                      'Your ride, on demand',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 1.8,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 380.ms, duration: 400.ms),

                  const SizedBox(height: 52),

                  // Progress dots
                  _BouncingDots(color: _AppColors.accent)
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 300.ms),
                ],
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 1,
                  color: _AppColors.txt3.withOpacity(0.25),
                ),
                const SizedBox(height: 10),
                Text(
                  'Powered by Bepay Ltd',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _AppColors.txt3.withOpacity(0.55),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Animated 3-dot loader ─────────────────────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  final Color color;
  const _BouncingDots({required this.color});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );

    _animations = _controllers.asMap().entries.map((e) {
      Future.delayed(Duration(milliseconds: e.key * 160), () {
        if (mounted) e.value.forward();
      });
      return Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: e.value, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: i == 1 ? 10 : 7,
              height: i == 1 ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 1
                    ? widget.color
                    : widget.color.withOpacity(0.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Subtle background grid ────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF16A34A).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}