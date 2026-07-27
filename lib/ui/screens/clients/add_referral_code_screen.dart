import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // NEW
import 'package:speed_ios/utils/colors.dart';
import 'package:speed_ios/states/verify/verify_otp_bloc.dart';

import '../../../routes/routes.names.dart'; // NEW — for `home`
import '../../../routes/routes.provider.dart'; // NEW — for safeGoNamed, if that's where it lives
import '../../../utils/notifiers.dart';

class _AppColors {
  static const bg = Color(0xFF0B1220);
  static const bg2 = Color(0xFF111827);
  static const bg4 = Color(0xFF202B3F);
  static const accent = Color(0xFF10B981);
  static const txt = Color(0xFFF8FAFC);
  static const txt2 = Color(0xFFCBD5E1);
  static const txt3 = Color(0xFF94A3B8);
  static const border = Color(0x14FFFFFF);
  static const gradientRide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );
}

class AddReferralCodeScreen extends StatefulWidget {
  final String? clientId;

  const AddReferralCodeScreen({Key? key, this.clientId}) : super(key: key);

  @override
  State<AddReferralCodeScreen> createState() => _AddReferralCodeScreenState();
}

class _AddReferralCodeScreenState extends State<AddReferralCodeScreen> {
  final TextEditingController _controller = TextEditingController();
  late VerifyOtpBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<VerifyOtpBloc>(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // NEW: safe close — pops if there's somewhere to go back to,
  // otherwise routes to home instead of crashing on an empty stack.
  void _closeScreen(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.safeGoNamed(home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        backgroundColor: _AppColors.bg2,
        elevation: 0,
        title: Text(
          'Referral code',
          style: GoogleFonts.poppins(
            color: _AppColors.txt,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _AppColors.txt),
        // NEW: override the default back button too, so the
        // AppBar's auto back-arrow doesn't hit the same crash
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _closeScreen(context),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: _AppColors.gradientRide,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                'Have a referral code?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.txt,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add it anytime to link your account with the friend who invited you.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: _AppColors.txt2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.poppins(
                  color: _AppColors.txt,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter referral code',
                  hintStyle:
                      GoogleFonts.poppins(color: _AppColors.txt3, fontSize: 13),
                  filled: true,
                  fillColor: _AppColors.bg4,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _AppColors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
                bloc: _bloc,
                listener: (context, state) {
                  if (state is AddReferralCodeSuccess) {
                    showSuccessAlert(state.message, context)
                        .then((_) => _closeScreen(context));
                  }
                  if (state is AddReferralCodeError) {
                    showErrorAlert(state.message, context);
                  }
                },
                builder: (context, state) {
                  final loading = state is AddReferralCodeLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _AppColors.gradientRide,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                final code = _controller.text.trim();
                                if (code.isEmpty) {
                                  showErrorAlert(
                                      'Enter a referral code first', context);
                                  return;
                                }
                                _bloc.add(HandleAddReferralCode(
                                  clientId: widget.clientId.toString(),
                                  referralCode: code,
                                ));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save code',
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
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _closeScreen(context), // CHANGED
                  child: Text(
                    'Not now',
                    style: GoogleFonts.poppins(
                      color: _AppColors.txt3,
                      fontWeight: FontWeight.w600,
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
}