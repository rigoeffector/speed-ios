import 'dart:io';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
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
  PickedFile? _pickedFile;
  final _picker = ImagePicker();

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
      // final pickedFile = await _picker.getImage(source: ImageSource.gallery);
      // if (pickedFile != null) {
      //   setState(() {
      //     _pickedFile = pickedFile;
      //   });
      // }
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
              const SizedBox(height: 5),
              _buildForm(),
              const SizedBox(height: 20),
              BlocConsumer<UpdateClientBloc, UpdateClientState>(
                listener: (context, state) {
                  if (state is UpdateClientLoading) {}
                  if (state is UpdateClientError) {
                    showErrorAlert(state.message, context);
                  }
                  if (state is UpdateClientSuccess) {
                    final obtainedUserId =
                        state.updateClientInfoModel.data!.first.id.toString();

                    context.goNamed(home, queryParameters: {
                      'userId': obtainedUserId,
                      'countryCode': "tz"
                    });
                  }
                },
                builder: (context, state) {
                  return MyButton(
                    title: "Update Profile",
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
                  );
                },
              )
            ],
          ),
        ),
        bottomSheet: Container(
          height: 40,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Please fill out the following information to complete your profile",
                style: GoogleFonts.rubik(
                  color: blackColor,
                  fontWeight: FontWeight.w300,
                  fontSize: 13,
                ),
              ),
            ),
            _buildTextField(
              label: "First Name".tr(),
              hint: "First name".tr(),
              controller: fnameController,
            ),
            _buildTextField(
              label: "Last Name".tr(),
              hint: "Enter last name".tr(),
              controller: lnameController,
            ),
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
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: greyColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: TextField(
            textAlign: TextAlign.left,
            controller: controller,
            cursorColor: Theme.of(context).primaryColor,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              border: InputBorder.none,
              hintStyle: GoogleFonts.poppins(
                fontSize: 12.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return BlocConsumer<UpdateClientBloc, UpdateClientState>(
      listener: (context, state) {
        if (state is UpdateClientLoading) {
          setState(() => isUpdateInfoLoading = true);
        } else if (state is UpdateClientError) {
          setState(() => isUpdateInfoLoading = false);
          showErrorAlert(state.message, context);
        } else if (state is UpdateClientSuccess) {
          setState(() => isUpdateInfoLoading = false);
          final obtainedUserId =
              state.updateClientInfoModel.data!.first.id.toString();
          setState(() {
            obtainedUserIdUpdated = obtainedUserId;
          });
          context.safeGoNamed(home,
              params: {'userId': obtainedUserId, 'countryCode': "tz"});
        }
      },
      builder: (context, state) {
        return MyButton(
          title: "Update Profile",
          isLoading: isUpdateInfoLoading,
          backgroundColor: primaryColor,
          onTap: () {
            if (isFormFilled()) {
              updateClientBloc.add(HandleUpdateClientInformation(
                clientId: widget.clientId.toString(),
                fname: fnameController.text.trim(),
                lname: lnameController.text.trim(),
              ));
            } else {
              showErrorAlert("Please fill all required fields", context);
            }
          },
        );
      },
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
        decoration: const BoxDecoration(color: primaryColor),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => _onWillPop(),
                icon: const Icon(Icons.arrow_back, color: whiteColor),
              ),
              Text(
                "Update Profile".tr(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: whiteColor,
                  fontSize: 17,
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
            ],
          ),
        ),
      ),
    );
  }
}
