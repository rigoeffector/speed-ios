// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:speed_ios/routes/routes.provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_country_code_picker/flutter_country_code_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/ui/widgets/heading.dart';
import 'package:speed_ios/utils/notifiers.dart';

import '../../../utils/colors.dart';
import '../../states/user.login/user_login_bloc.dart';
import '../widgets/forms/email_text_input.dart';

class Login extends StatefulWidget {
  const Login({
    Key? key,
  }) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  UserLoginBloc loginBloc = UserLoginBloc(UserLoginInitial(), AuthService());
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String sentOtp = "";
  String? token;
  bool isRegisterLoading = false;
  bool isPhone = false;
  bool _passwordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();

    loginBloc = BlocProvider.of<UserLoginBloc>(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Image.asset(
                    "assets/images/lock.png",
                    scale: 4,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Heading(
                    title: 'Client Login',
                    subtitle:
                        'Please enter your email/phone and password in field bellow',
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 10),
                    child: Form(
                      key: formKey,
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 15),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              decoration: BoxDecoration(
                                  color: whiteColor1,
                                  borderRadius: BorderRadius.circular(33)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          isPhone = true;
                                          _emailController.text = '';
                                          _passwordController.text = '';
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 5),
                                        decoration: BoxDecoration(
                                            color: isPhone
                                                ? primaryColor
                                                : whiteColor1,
                                            borderRadius:
                                                BorderRadius.circular(29)),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.call,
                                                color: isPhone
                                                    ? whiteColor1
                                                    : primaryColor,
                                                size: 18,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 10),
                                                child: Text(
                                                  "Phone ",
                                                  style: GoogleFonts.poppins(
                                                      color: isPhone
                                                          ? whiteColor
                                                          : primaryColor,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          isPhone = false;
                                          _emailController.text = '';
                                          _passwordController.text = '';
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 5),
                                        decoration: BoxDecoration(
                                            color: !isPhone
                                                ? primaryColor
                                                : whiteColor1,
                                            borderRadius:
                                                BorderRadius.circular(29)),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.mail,
                                                color: !isPhone
                                                    ? whiteColor
                                                    : primaryColor,
                                                size: 18,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 10),
                                                child: Text(
                                                  "Email",
                                                  style: GoogleFonts.poppins(
                                                      color: !isPhone
                                                          ? whiteColor
                                                          : primaryColor,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: isPhone,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: IntlPhoneField(
                                  maxLength: 10,
                                  controller: _emailController,
                                  initialCountryCode: "US",
                                  validator: (data) {
                                    return null;
                                  },
                                  onChanged: (data) {
                                    // number = data;
                                    print("number is $data");
                                  },
                                  hintText: 'Phone number',
                                ),
                              ),
                            ),
                            Visibility(
                              visible: !isPhone,
                              child: TextInputFieldEmailaAddress(
                                  _emailController, "Email address"),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1.0, color: greyColor1)),
                              padding:
                                  const EdgeInsets.only(right: 0, left: 15),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 5),
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _passwordController,
                                obscureText: !_passwordVisible,
                                style: GoogleFonts.poppins(fontSize: 13.0),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      // Based on passwordVisible state choose the icon
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: greyColor1,
                                      size: 23,
                                    ),
                                    onPressed: () {
                                      // Update the state i.e. toogle the state of passwordVisible variable
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
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
                                          "If you dont have account in our system  ",
                                          style: GoogleFonts.rubik(
                                              color: blackColor,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 13),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  context.safeGoNamed(verify),
                                              child: Text(
                                                "Create Account",
                                                style: GoogleFonts.rubik(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: BlocConsumer<UserLoginBloc, UserLoginState>(
                  listener: (context, state) {
                    if (state is UserLoginError) {
                      showErrorAlert(state.message, context);
                      setState(() {
                        isRegisterLoading = false;
                      });
                    }
                    if (state is UserLoginLoading) {
                      setState(() {
                        isRegisterLoading = true;
                      });
                    }
                    if (state is UserLoginSuccess) {
                      setState(() {
                        isRegisterLoading = false;
                      });

                      String obtainedClientId =
                          state.userLoginModel.userLoginData!.id.toString();

                      context.safeGoNamed(home, params: {
                        'userId': obtainedClientId,
                      });
                    }
                  },
                  builder: (context, state) {
                    return MyButton(
                      backgroundColor: primaryColor,
                      titleColor: whiteColor,
                      title: 'Login'.tr(),
                      onTap: () {
                        if (_emailController.text.isEmpty &&
                            _passwordController.text.isEmpty) {
                          showErrorAlert(
                              "Please fill username and password", context);
                        } else {
                          loginBloc.add(HandleUSerLogin(
                              email: _emailController.text.toString(),
                              password: _passwordController.text.toString()));
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
    );
  }
}
