import 'dart:io';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/states/register.client/register_client_bloc.dart';
import 'package:speed_ios/states/update.client/update_client_bloc.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/colors.dart';

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
  static const border = Color(0x18FFFFFF);

  static const gradientRide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF0F766E)],
  );
}

class ClientProfileScreen extends StatefulWidget {
  final String? clientId;
  final String? name;
  final String? phone;
  const ClientProfileScreen({Key? key, this.clientId, this.name, this.phone})
      : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with TickerProviderStateMixin {
  UpdateClientBloc updateClientBloc =
      UpdateClientBloc(UpdateClientInitial(), AuthService());
  final RegisterClientBloc registerClientBloc =
      RegisterClientBloc(RegisterClientInitial(), AuthService());
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  String? _focusedField;

  @override
  void initState() {
    super.initState();
    updateClientBloc = BlocProvider.of<UpdateClientBloc>(context);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.name != null) {
      final names = widget.name!.split(' ');
      if (names.isNotEmpty) fnameController.text = names.first;
      if (names.length > 1) lnameController.text = names.last;
    }
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool isFormFilled() =>
      fnameController.text.trim().isNotEmpty &&
      lnameController.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) setState(() => _pickedFile = pickedFile);
    } catch (e) {
      showErrorAlert("Failed to pick image", context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!isFormFilled()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _AppColors.bg3,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Incomplete Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.txt,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill out all required fields before leaving.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _AppColors.txt2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Keep Editing',
                          style: GoogleFonts.poppins(
                            color: _AppColors.txt2,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.safeGoNamed(verify);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          'Discard',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _AppColors.bg,
        body: Stack(
          children: [
            // ── Background orbs ───────────────────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: 0.14 + _pulseController.value * 0.08,
                  child: Container(
                    width: 280,
                    height: 280,
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
            Positioned(
              bottom: 80,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: 0.10 + _pulseController.value * 0.06,
                  child: Container(
                    width: 240,
                    height: 240,
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

            // ── Main scroll content ───────────────────────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      _buildProfileImageSection()
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 500.ms)
                          .scale(
                            begin: const Offset(0.78, 0.78),
                            curve: Curves.elasticOut,
                            duration: 700.ms,
                          ),
                      const SizedBox(height: 32),
                      _buildStepIndicator()
                          .animate()
                          .fadeIn(delay: 280.ms, duration: 400.ms),
                      const SizedBox(height: 28),
                      _buildForm()
                          .animate()
                          .fadeIn(delay: 380.ms, duration: 500.ms)
                          .slideY(begin: 0.12, end: 0),
                      const SizedBox(height: 28),
                      BlocConsumer<UpdateClientBloc, UpdateClientState>(
                        listener: (context, state) {
                          if (state is UpdateClientError) {
                            showErrorAlert(state.message, context);
                          }
                          if (state is UpdateClientSuccess) {
                            final id = state.updateClientInfoModel.data!.id
                                .toString();
                            context.goNamed(home,
                                queryParameters: {'userId': id, 'countryCode': 'tz'});
                          }
                        },
                        builder: (context, state) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildSubmitButton(
                              isLoading: state is UpdateClientLoading,
                              onTap: () {
                                if (isFormFilled()) {
                                  updateClientBloc.add(
                                    HandleUpdateClientInformation(
                                      clientId: widget.clientId.toString(),
                                      fname: fnameController.text.trim(),
                                      lname: lnameController.text.trim(),
                                    ),
                                  );
                                } else {
                                  showErrorAlert(
                                      "Please fill all required fields",
                                      context);
                                }
                              },
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 520.ms, duration: 500.ms)
                              .slideY(begin: 0.08, end: 0);
                        },
                      ),
                      const SizedBox(height: 40),
                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: _AppColors.txt3.withOpacity(0.3),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Powered by Mopay',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _AppColors.txt3.withOpacity(0.5),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 1,
                              color: _AppColors.txt3.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _AppColors.bg2,
      leading: IconButton(
        onPressed: _onWillPop,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _AppColors.border,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: _AppColors.txt,
            size: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 14),
        title: Text(
          "Update Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: _AppColors.txt,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AppColors.bg2, _AppColors.bg3],
            ),
          ),
          child: Stack(
            children: [
              // Decorative diagonal stripe
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(painter: _HeaderStripePainter()),
              ),
              // Accent line at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _AppColors.accent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Outer glow ring
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      _AppColors.accent,
                      _AppColors.accent2,
                      _AppColors.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.accent.withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AppColors.bg3,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: _AppColors.bg4,
                        child: _pickedFile != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_pickedFile!.path),
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                size: 60,
                                color: _AppColors.txt3,
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Camera button
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AppColors.accent, _AppColors.accent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.bg, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _AppColors.accent.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
                    .animate(
                        onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 1800.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.12, 1.12),
                      curve: Curves.easeInOut,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.name?.isNotEmpty == true ? widget.name! : 'New Account',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _AppColors.txt,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.phone ?? '',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _AppColors.txt3,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepDot(active: true, label: 'Phone'),
        _StepLine(),
        _StepDot(active: true, label: 'OTP'),
        _StepLine(),
        _StepDot(active: true, label: 'Profile', isCurrent: true),
        _StepLine(faded: true),
        _StepDot(active: false, label: 'Home'),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AppColors.bg2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _AppColors.accent.withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: _AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Personal Info",
                        style: GoogleFonts.poppins(
                          color: _AppColors.txt,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "How should we call you?",
                        style: GoogleFonts.poppins(
                          color: _AppColors.txt3,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _AppColors.border,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            _buildTextField(
              label: "First Name",
              hint: "Enter your first name",
              controller: fnameController,
              icon: Icons.badge_outlined,
              fieldKey: 'fname',
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),

            const SizedBox(height: 18),

            _buildTextField(
              label: "Last Name",
              hint: "Enter your last name",
              controller: lnameController,
              icon: Icons.badge_outlined,
              fieldKey: 'lname',
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required String fieldKey,
  }) {
    final isFocused = _focusedField == fieldKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isFocused ? _AppColors.accent : _AppColors.txt3,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isFocused
                ? _AppColors.accent.withOpacity(0.06)
                : _AppColors.bg3,
            border: Border.all(
              color: isFocused
                  ? _AppColors.accent.withOpacity(0.6)
                  : _AppColors.border,
              width: isFocused ? 1.5 : 1,
            ),
          ),
          child: Focus(
            onFocusChange: (hasFocus) =>
                setState(() => _focusedField = hasFocus ? fieldKey : null),
            child: TextField(
              controller: controller,
              cursorColor: _AppColors.accent,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _AppColors.txt,
              ),
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                border: InputBorder.none,
                prefixIcon: Icon(
                  icon,
                  color: isFocused
                      ? _AppColors.accent
                      : _AppColors.txt3,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _AppColors.txt3.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    _AppColors.bg4,
                    _AppColors.bg4,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_AppColors.accent, _AppColors.accent2],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _AppColors.accent.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_AppColors.txt3),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Step indicator widgets ────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final bool isCurrent;
  final String label;
  const _StepDot({
    required this.active,
    required this.label,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 32 : 20,
          height: isCurrent ? 32 : 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    colors: [_AppColors.accent, _AppColors.accent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : _AppColors.bg3,
            border: Border.all(
              color: active ? Colors.transparent : _AppColors.border,
              width: 1.5,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: _AppColors.accent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: isCurrent
              ? const Icon(Icons.person_outline, color: Colors.white, size: 16)
              : active
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: active ? _AppColors.accent : _AppColors.txt3,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool faded;
  const _StepLine({this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: faded
              ? [_AppColors.accent2, _AppColors.bg3]
              : [_AppColors.accent, _AppColors.accent2],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Header background painter ─────────────────────────────────────────────────

class _HeaderStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF16A34A).withOpacity(0.05)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    for (double x = -40; x < size.width + 40; x += 32) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeaderStripePainter old) => false;
}