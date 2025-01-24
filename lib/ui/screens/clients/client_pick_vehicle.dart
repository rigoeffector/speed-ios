import 'dart:async';

import 'package:speed_ios/controllers/home_controller.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_normal.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_outlined.dart';
import 'package:speed_ios/ui/widgets/lists/item_select_car_widget.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientPickVehicle extends StatefulWidget {
  const ClientPickVehicle({Key? key}) : super(key: key);

  @override
  State<ClientPickVehicle> createState() => _ClientPickVehicleState();
}

class _ClientPickVehicleState extends State<ClientPickVehicle> {
  final controller = HomeController();
  void _onSelectCity() {
    controller.changeHomeState(HomeState.selectCity);
  }

  String selectedId = "0";
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: _appBar(AppBar().preferredSize.height),
      body: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => LayoutBuilder(
                builder: (context, BoxConstraints constraints) => Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/images/back.jpg"),
                                  fit: BoxFit.cover)),
                        ),
                        Positioned(
                            child: Container(
                          color: whiteColor2,
                        )),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 500),
                          top: controller.homeState == HomeState.normal
                              ? 10
                              : -50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 300,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: whiteColor,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xffEDEDED),
                                          spreadRadius: 2,
                                          blurRadius: 3,
                                          offset: Offset(0,
                                              2), // changes position of shadow
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          "Select your car",
                                          maxLines: 1,
                                          softWrap: false,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.fade,
                                          style: GoogleFonts.poppins(
                                              color: primaryColor1,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 240,
                                        child: ListView(
                                          children: [
                                            SelectCarItemWidget(
                                              id: "1",
                                              photo:
                                                  "assets/images/basic_car.png",
                                              title: "Lexus L2",
                                              selectedId: selectedId,
                                              plate: "CAB911",
                                              price: "15",
                                              onTap: () {
                                                setState(() {
                                                  selectedId = "1";
                                                  controller.changeHomeState(
                                                      HomeState.selectCity);
                                                });
                                              },
                                            ),
                                            SelectCarItemWidget(
                                                id: "2",
                                                photo:
                                                    "assets/images/confort_car.png",
                                                title: "Toyota Versso",
                                                selectedId: selectedId,
                                                onTap: () {
                                                  setState(() {
                                                    selectedId = "2";
                                                    controller.changeHomeState(
                                                        HomeState.selectCity);
                                                  });
                                                },
                                                plate: "CAB322",
                                                price: "10"),
                                            SelectCarItemWidget(
                                              id: "3",
                                              photo:
                                                  "assets/images/cheap_car.png",
                                              title: "client Basic",
                                              selectedId: selectedId,
                                              plate: "CAB434",
                                              price: "5",
                                              onTap: () {
                                                setState(() {
                                                  selectedId = "3";
                                                  controller.changeHomeState(
                                                      HomeState.selectCity);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            bottom: 78,
                            left: 0,
                            height: controller.homeState == HomeState.normal
                                ? 0
                                : 210,
                            right: 0,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                  color: whiteColor,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xffEDEDED),
                                      spreadRadius: 2,
                                      blurRadius: 3,
                                      offset: Offset(
                                          0, 2), // changes position of shadow
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "Searching Nearby Driver",
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.fade,
                                      style: GoogleFonts.poppins(
                                          color: primaryColor1,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14),
                                    ),
                                  ),
                                  driverFound()
                                ],
                              ),
                            )),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: MyButton(
                                      title: 'Lets Go'.tr(),
                                      titleColor: whiteColor,
                                      backgroundColor: primaryColor,
                                      onTap: () {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        Timer(const Duration(milliseconds: 800),
                                            () {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        });
                                      },
                                      isLoading: isLoading),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),
          )),
    );
  }

  Widget driverFound() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                              image: AssetImage("assets/images/avatar.jpg"))),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: whiteColor, width: 2.4),
                            image: const DecorationImage(
                                image: AssetImage(
                                    "assets/images/confort_car.png"))),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        "Muhmmad Junior",
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        "Toyota Vitz",
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                            fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        "CAB223F",
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontWeight: FontWeight.w300,
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                MyIconButton(
                  title: "Call Now",
                  icon: Icons.call,
                  titleColor: whiteColor,
                  backgroundColor: primaryColor,
                  width: 100,
                ),
                MyOutlineButton(
                  title: "Cancel",
                  icon: Icons.close,
                  titleColor: redColor,
                  backgroundColor: whiteColor,
                  width: 100,
                  onTap: () {
                    controller.changeHomeState(HomeState.normal);
                  },
                )
              ],
            )
          ],
        ),
      );

  _appBar(height) => PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, height + 5),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/back.jpg"),
                      fit: BoxFit.none)),
            ), //
            Container(
              height: height + 30,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: whiteColor2), // Background
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: blackColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9.0),
                      child: Text("Select your car",
                          style: GoogleFonts.poppins(
                              color: blackColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 17)),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.settings,
                          color: whiteColor2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ), // Required some widget in between to float AppBar
          ],
        ),
      );
}
