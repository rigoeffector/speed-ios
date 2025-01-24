import 'dart:io';

import 'package:speed_ios/states/update.profile/update_profile_bloc.dart';
import 'package:speed_ios/ui/screens/clients/set_destination.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/utils/notifiers.dart';
import 'package:speed_ios/utils/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/user_model.dart';
import '../../states/client.profile.data/client_profile_bloc.dart';
import '../../utils/colors.dart';
import '../widgets/buttons/icon_button_normal.dart';
import '../widgets/forms/item_text_widget_normal.dart';
import '../widgets/lists/item_row_profile.dart';
import 'clients/favorite_pickup_location.dart';

class UserProfile extends StatefulWidget {
  final String? userId;
  const UserProfile({Key? key, this.userId}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  ClientProfileBloc _profileBloc =
      ClientProfileBloc(ClientProfileInitial(), AuthService());

  UpdateProfileBloc updateClientAccountBloc =
      UpdateProfileBloc(UpdateProfileInitial(), AuthService());

  String date = "";
  String? lang;
  int id = 1;
  bool isSelected = false;
  bool isLang = false;
  bool isLoading = false;
  bool _isLogouting = false;
  String? logger, loggerPhone;
  bool showProduct = false;
  bool showCashInOut = false;
  String? currentName,
      currentPhone,
      currentCategory,
      currentGender,
      currentAddress,
      currPhone,
      currCity;
  String currentProfile = "";
  late ClientData user;

  bool isEDiting = false;
  bool isPhoneEditing = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _profileBloc = BlocProvider.of<ClientProfileBloc>(context);
    updateClientAccountBloc = BlocProvider.of<UpdateProfileBloc>(context);
  }

  @override
  void didChangeDependencies() {
    _profileBloc
        .add(FetchAllClientInformation(clientId: widget.userId.toString()));
    super.didChangeDependencies();
  }

  File? _image;
  PickedFile? _pickedFile;
  final _picker = ImagePicker();
  // Implementing the image picker
  Future<void> _pickImage() async {
    // _pickedFile = await _picker.getImage(source: ImageSource.gallery);
    // if (_pickedFile != null) {
    //   setState(() {
    //     _image = File(_pickedFile!.path);
    //   });
    // }
  }

  void _toggle() {
    setState(() {
      isPhoneEditing = !isPhoneEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: Stack(
          children: [
            Scaffold(
              key: scaffoldKey,
              appBar: _appBar(AppBar().preferredSize.height),
              backgroundColor: whiteColor,
              body: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Positioned(
                            child: Container(
                                height: 120,
                                padding: const EdgeInsets.only(bottom: 5),
                                decoration: const BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15)),
                                ))),
                        Container(
                          margin: const EdgeInsets.only(
                              bottom: 5, left: 10, right: 10, top: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isEDiting
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: whiteColor,
                                        boxShadow: const [
                                          BoxShadow(
                                            offset: Offset(0.2, 1.0),
                                            color: Color(0xffEDEDED),
                                            blurRadius: 2.0,
                                          ),
                                        ],
                                      ),
                                      child: Form(
                                        key: formKey,
                                        child: Column(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                      width: 130,
                                                      height: 130,
                                                    ),
                                                    _pickedFile != null
                                                        ? Container(
                                                            alignment: Alignment
                                                                .center,
                                                            width: 120,
                                                            height: 120,
                                                            // color: Colors.grey[300],
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color:
                                                                      greyColor,
                                                                  width: 4),
                                                            ),

                                                            child: CircleAvatar(
                                                              radius: 73,
                                                              child: ClipOval(
                                                                child:
                                                                    Image.file(
                                                                  File(_pickedFile!
                                                                      .path),
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: 120,
                                                                  height: 120,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Container(
                                                            height: 120,
                                                            width: 120,
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        5),
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color:
                                                                        primaryColorOverlay,
                                                                    width: 3),
                                                                image: const DecorationImage(
                                                                    image: AssetImage(
                                                                        "assets/images/profile.png"),
                                                                    fit: BoxFit
                                                                        .fill)),
                                                          ),
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(2),
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              primaryColorOverlay,
                                                        ),
                                                        child: Center(
                                                          child: IconButton(
                                                              onPressed: () {
                                                                _pickImage();
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .camera_alt_rounded,
                                                                color:
                                                                    primaryColor,
                                                              )),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: 14,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            TextInputFieldNormal(
                                              nameController,
                                              "Full name *",
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      width: 1.1,
                                                      color: whiteColor1)),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 5),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 2,
                                                          horizontal: 15),
                                                      child: TextFormField(
                                                          textAlign:
                                                              TextAlign.left,
                                                          keyboardType:
                                                              TextInputType
                                                                  .text,
                                                          enabled:
                                                              isPhoneEditing,
                                                          controller:
                                                              phoneController,
                                                          cursorColor:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: "Phone",
                                                            counterText: '',
                                                            border: InputBorder
                                                                .none,
                                                            hintStyle: GoogleFonts
                                                                .poppins(
                                                                    fontSize:
                                                                        12.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300),
                                                          )),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      // Based on passwordVisible state choose the icon
                                                      isPhoneEditing
                                                          ? Icons.close_outlined
                                                          : Icons.edit,
                                                      color: greyColor1,
                                                      size: 18,
                                                    ),
                                                    onPressed: _toggle,
                                                  )
                                                ],
                                              ),
                                            ),
                                            BlocConsumer<UpdateProfileBloc,
                                                UpdateProfileState>(
                                              listener: (context, state) {
                                                if (state
                                                    is UpdateClientLoading) {
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                }
                                                if (state
                                                    is UpdateProfileError) {
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  showErrorAlert(
                                                      state.message, context);
                                                }
                                                if (state
                                                    is UpdateProfileSuccess) {
                                                  setState(() {
                                                    isLoading = false;
                                                    isEDiting = false;
                                                  });
                                                }
                                              },
                                              builder: (context, state) {
                                                return Row(
                                                  children: [
                                                    MyIconButton(
                                                      title: isLoading
                                                          ? "Loading..."
                                                          : "Update Profile",
                                                      titleColor: whiteColor,
                                                      backgroundColor:
                                                          primaryColor,
                                                      onTap: () {
                                                        if (nameController
                                                            .text.isNotEmpty) {
                                                          updateClientAccountBloc
                                                              .add(
                                                                  HandleUpdateProfileInformation(
                                                            clientId: widget
                                                                .userId
                                                                .toString(),
                                                            clientName:
                                                                nameController
                                                                    .text,
                                                            photo: _pickedFile!,
                                                          ));
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isEDiting = false;
                                                  });
                                                },
                                                child: Text(
                                                  "Close",
                                                  style: GoogleFonts.poppins(
                                                      color: orangeColor),
                                                ))
                                          ],
                                        ),
                                      ),
                                    )
                                  : BlocConsumer<ClientProfileBloc,
                                      ClientProfileState>(
                                      listener: (context, state) {
                                        if (state is ClientProfileSuccess) {
                                          currentName =
                                              "${state.clientProfileModel.data!.first.fname} ${state.clientProfileModel.data!.first.lname}";
                                          currentPhone = state
                                              .clientProfileModel
                                              .data!
                                              .first
                                              .phone
                                              .toString();
                                          phoneController.text = state
                                              .clientProfileModel
                                              .data!
                                              .first
                                              .phone
                                              .toString();
                                        }
                                      },
                                      builder: (context, state) {
                                        if (state is ClientProfileLoading) {
                                          return const SpinKitCircle(
                                            size: 50,
                                            color: whiteColor,
                                          );
                                        }
                                        if (state is ClientProfileSuccess) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: whiteColor,
                                              boxShadow: const [
                                                BoxShadow(
                                                  offset: Offset(0.6, 5.0),
                                                  color: Color(0xffEDEDED),
                                                  blurRadius: 5.0,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                            height: 70,
                                                            width: 70,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 7,
                                                                    top: 7,
                                                                    right: 10),
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color:
                                                                        whiteColor1,
                                                                    width: 3),
                                                                image: DecorationImage(
                                                                    fit: BoxFit
                                                                        .contain,
                                                                    image: NetworkImage(
                                                                        dotenv.get(
                                                                            "clientProfileUrl"))))),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const SizedBox(
                                                              height: 14,
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                SizedBox(
                                                                  width: 200,
                                                                  child: Text(
                                                                    "$currentName",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts.poppins(
                                                                        color:
                                                                            primaryColor,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                SizedBox(
                                                                  width: 180,
                                                                  child: Text(
                                                                    "$currentPhone",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w300),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return const Text("");
                                      },
                                    ),
                              const SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 15),
                                child: Text(
                                  "My Account".tr(),
                                  style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      offset: Offset(0.6, 5.0),
                                      color: Color(0xffEDEDED),
                                      blurRadius: 5.0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    ItemRowProfile(
                                        title: "My Locations",
                                        icon: CupertinoIcons.location_fill,
                                        iconColor: greyColor,
                                        isLang: false,
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MyPageRoute(
                                                  widget:
                                                      FavoritePickUpLocation(
                                                clientId:
                                                    widget.userId.toString(),
                                              )));
                                        },
                                        image: ''),
                                    ItemRowProfile(
                                        title: "My History",
                                        icon: CupertinoIcons.car,
                                        iconColor: greyColor,
                                        isLang: false,
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MyPageRoute(
                                                  widget: SetDestination(
                                                userId:
                                                    widget.userId.toString(),
                                              )));
                                          // context.safeGoNamed(myHistory,
                                          //     queryParameters: {
                                          //       'clientId':
                                          //           widget.userId.toString()
                                          //     });
                                        },
                                        image: ''),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 15),
                                child: Text(
                                  "Preferences",
                                  style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      offset: Offset(0.6, 5.0),
                                      color: Color(0xffEDEDED),
                                      blurRadius: 5.0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // ItemRowProfile(
                                    //     title: "app_txt_change_password".tr(),
                                    //     icon: CupertinoIcons.lock_fill,
                                    //     iconColor: greyColor,
                                    //     isLang: false,
                                    //     onTap: (){
                                    //       Navigator.push(context, MyPageRoute(widget: const LoginClient()));
                                    //     },
                                    //     image: ''),
                                    //

                                    ItemRowProfile(
                                      title: "Logout",
                                      icon: Icons.logout,
                                      iconColor: greyColor,
                                      isLang: false,
                                      image: '',
                                      onTap: () async {
                                        final pref = await SharedPreferences
                                            .getInstance();
                                        await pref.remove("currentClient");
                                        await pref.remove("isLoggedIn");
                                        pref.setBool('isPasswordChanged', true);
                                        setState(() {
                                          _isLogouting = true;
                                        });

                                        Future.delayed(
                                            const Duration(seconds: 4), () {
                                          setState(() {
                                            _isLogouting = false;
                                          });
                                          Phoenix.rebirth(context);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Visibility(
              visible: _isLogouting,
              child: Positioned(
                  child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: primaryColorOverlay1,
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SpinKitSpinningLines(
                            color: whiteColor,
                            size: 60,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 15),
                            child: Text(
                              "Logging out",
                              style: GoogleFonts.poppins(
                                  color: whiteColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  _appBar(height) => PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, height + 15),
        child: Stack(
          children: <Widget>[
            Container(
              color: primaryColor,
            ),
            Container(
              height: height + 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(
                  top: 40, left: 10, right: 10, bottom: 10),
              decoration: const BoxDecoration(
                color: primaryColor,
              ), // Background
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            context.pop(true);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: whiteColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          child: Text(
                            "Client Profile",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: whiteColor,
                                fontSize: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            isEDiting = true;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: primaryColorOverlay),
                          child: const Stack(
                            children: [
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Icon(
                                  Icons.edit,
                                  color: whiteColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Required some widget in between to float AppBar
          ],
        ),
      );
}
