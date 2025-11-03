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
import 'package:flutter_animate/flutter_animate.dart'; // Added for elegant animations
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

  @override
  void initState() {
    super.initState();
    updateClientBloc = BlocProvider.of<UpdateClientBloc>(context);
    // Pre-fill name if provided
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
    super.dispose();
  }

  bool isFormFilled() {
    return fnameController.text.trim().isNotEmpty &&
        lnameController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Incomplete Form',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            content: Text(
              'Please fill out all required fields before leaving.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continue Editing',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.safeGoNamed(verify); // Force navigation to home
                },
                child: Text(
                  'Discard Changes',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
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

  void _handleSkip() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Skip Profile Update?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'Are you sure you want to skip updating your profile?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Editing',
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.safeGoNamed(home);
              },
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: whiteColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildProfileImageSection()
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(),
              const SizedBox(height: 30),
              _buildForm()
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.1, end: 0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyButton(
                      title: "Update Profile".tr(),
                      isLoading: state is UpdateClientLoading,
                      backgroundColor: primaryColor,
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
                      .fadeIn(delay: 600.ms)
                      .scale(curve: Curves.elasticOut);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        bottomSheet: Container(
          color: primaryColor.withOpacity(0.9),
          height: 40,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: whiteColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: _pickedFile != null
                ? ClipOval(
                    child: Image.file(
                      File(_pickedFile!.path),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 60,
                    color: primaryColor,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: whiteColor, width: 2),
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
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please fill out the following information to complete your profile",
              style: GoogleFonts.poppins(
                color: blackColor,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            _buildTextField(
              label: "First Name".tr(),
              hint: "First name".tr(),
              controller: fnameController,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Last Name".tr(),
              hint: "Enter last name".tr(),
              controller: lnameController,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: greyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: greyColor.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            textAlign: TextAlign.left,
            controller: controller,
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintStyle: GoogleFonts.poppins(
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color: greyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size(MediaQuery.of(context).size.width,
          AppBar().preferredSize.height + 25),
      child: Container(
        height: AppBar().preferredSize.height + 40,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(top: 20),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => _onWillPop(),
                icon: const Icon(Icons.arrow_back, color: whiteColor),
                padding: const EdgeInsets.only(left: 16),
              ),
              Expanded(
                child: Text(
                  "Update Profile".tr(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: whiteColor,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // TextButton(
              //   onPressed: _handleSkip,
              //   child: Text(
              //     "Skip".tr(),
              //     style: GoogleFonts.poppins(
              //       fontWeight: FontWeight.w500,
              //       color: whiteColor,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
