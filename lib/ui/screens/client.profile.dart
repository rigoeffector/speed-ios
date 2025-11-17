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
import '../../model/auth/register.client.model.dart';
import '../widgets/buttons/button.dart';

class ClientProfileScreen extends StatefulWidget {
  final String? clientId;
  final String? name;
  final String? phone;
  const ClientProfileScreen({Key? key, this.clientId, this.name, this.phone})
      : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  UpdateClientBloc updateClientBloc =
      UpdateClientBloc(UpdateClientInitial(), AuthService());
  final RegisterClientBloc registerClientBloc =
      RegisterClientBloc(RegisterClientInitial(), AuthService());
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var obtainedUserIdUpdated;
  bool isUpdateInfoLoading = false;
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  final FocusNode _fnameFocus = FocusNode();
  final FocusNode _lnameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    updateClientBloc = BlocProvider.of<UpdateClientBloc>(context);
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
    _fnameFocus.dispose();
    _lnameFocus.dispose();
    super.dispose();
  }

  bool isFormFilled() {
    return fnameController.text.trim().isNotEmpty &&
        lnameController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
        });
      }
    } catch (e) {
      showErrorAlert("Failed to pick image", context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!isFormFilled()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Incomplete Form',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Please fill out all required fields before leaving.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: greyColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue Editing',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.safeGoNamed(verify);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Discard Changes',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            // Background gradient
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileImageSection()
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 30),
                    _buildForm()
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 30),
                    BlocConsumer<UpdateClientBloc, UpdateClientState>(
                      listener: (context, state) {
                        if (state is UpdateClientLoading) {}
                        if (state is UpdateClientError) {
                          showErrorAlert(state.message, context);
                        }
                        if (state is UpdateClientSuccess) {
                          final obtainedUserId =
                              state.updateClientInfoModel.data!.id.toString();
                          context.goNamed(home, queryParameters: {
                            'userId': obtainedUserId,
                            'countryCode': "tz"
                          });
                        }
                      },
                      builder: (context, state) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildModernButton(
                            title: "Update Profile".tr(),
                            isLoading: state is UpdateClientLoading,
                            onTap: () {
                              if (isFormFilled()) {
                                updateClientBloc.add(HandleUpdateClientInformation(
                                  clientId: widget.clientId.toString(),
                                  fname: fnameController.text.trim(),
                                  lname: lnameController.text.trim(),
                                ));
                              } else {
                                showErrorAlert(
                                    "Please fill all required fields", context);
                              }
                            },
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 600.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              curve: Curves.easeOutBack,
                            );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.95),
                primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          height: 45,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: whiteColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Outer glow effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: whiteColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Main avatar
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: whiteColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _pickedFile != null
                      ? Image.file(
                          File(_pickedFile!.path),
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: whiteColor,
                          child: Icon(
                            Icons.person_outline,
                            size: 70,
                            color: primaryColor.withOpacity(0.5),
                          ),
                        ),
                ),
              ),
              // Camera button
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: whiteColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: whiteColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Tap to change photo",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: whiteColor.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
            Center(
              child: Column(
                children: [
                  Text(
                    "Complete Your Profile",
                    style: GoogleFonts.poppins(
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    "Fill out the information below",
                    style: GoogleFonts.poppins(
                      color: greyColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              label: "First Name".tr(),
              hint: "Enter your first name".tr(),
              controller: fnameController,
              focusNode: _fnameFocus,
              icon: Icons.person_outline,
            ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildTextField(
              label: "Last Name".tr(),
              hint: "Enter your last name".tr(),
              controller: lnameController,
              focusNode: _lnameFocus,
              icon: Icons.person_outline,
            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: blackColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focusNode.hasFocus
                  ? primaryColor
                  : Colors.grey.withOpacity(0.2),
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: primaryColor,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: blackColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus ? primaryColor : greyColor,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: greyColor.withOpacity(0.7),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: whiteColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: whiteColor,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _onWillPop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: whiteColor,
              size: 18,
            ),
          ),
        ),
        title: Text(
          "Update Profile".tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: whiteColor,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}