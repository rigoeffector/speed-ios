import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_normal.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_outlined.dart';

import '../../../controllers/home_controller.dart';
import '../../../model/nearby_driver_model.dart';
import '../../../utils/colors.dart';

class DriverProfile extends StatelessWidget {
  NearbyDriverData driver;
  DriverProfile({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Available",
                style: GoogleFonts.poppins(
                    color: greenColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Row(
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
                              color: whiteColor,
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
                        width: 130,
                        child: Text(
                          "${driver.driverName}",
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.poppins(
                              color: blackColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Text(
                          "${driver.carName}",
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.poppins(
                              color: blackColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 11),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          "${driver.driverCategory}",
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.poppins(
                              color: greenColor,
                              fontWeight: FontWeight.w300,
                              fontSize: 10),
                        ),
                      ),
                      RatingBar.builder(
                        initialRating: 3.3,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 15,
                        itemPadding: const EdgeInsets.symmetric(
                            horizontal: 1.0, vertical: 6),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: greenColor,
                        ),
                        onRatingUpdate: (rating) {
                          print(rating);
                        },
                      )
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text("\$${driver.price}",
                        style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text("app_txt_per_km".tr(),
                        style: GoogleFonts.poppins(
                            color: blackColor,
                            fontWeight: FontWeight.w200,
                            fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              MyIconButton(
                title: "app_txt_call_now".tr(),
                icon: Icons.call,
                titleColor: whiteColor,
                backgroundColor: primaryColor,
                width: 100,
                onTap: () async {
                  FlutterPhoneDirectCaller.callNumber("${driver.driverPhone}");
                },
              ),
              MyOutlineButton(
                title: "app_txt_pick_me".tr(),
                icon: Icons.place,
                titleColor: greenColor,
                backgroundColor: whiteColor,
                width: 100,
                onTap: () {
                  // controller.changeHomeState(HomeState.setDestination);
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
