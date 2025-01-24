import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class DriverItemRow extends StatelessWidget {
  final String? driverId;
  final String? selectedDriverId;
  final String? driverName;
  final String? driverPhone;
  final String? photo;
  final String? carName;
  final String? carPlateNo;
  final String? carColor;
  final String? distance;
  final Function()? onTAp;
  const DriverItemRow(
      {super.key,
      this.driverId,
      this.selectedDriverId,
      this.driverName,
      this.driverPhone,
      this.photo,
      this.carName,
      this.carPlateNo,
      this.carColor,
      this.onTAp,
      this.distance});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTAp,
      child: Row(
        children: [
          Container(
            height: 70,
            width: MediaQuery.of(context).size.width - 30,
            padding: const EdgeInsets.symmetric(vertical: 2),
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
                color: whiteColor1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    width: selectedDriverId == driverId ? 1 : 0,
                    color: selectedDriverId == driverId
                        ? primaryColor
                        : whiteColor1)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: photo == ""
                                      ? const NetworkImage(
                                          "https://thumbs.dreamstime.com/b/default-avatar-profile-icon-social-media-user-vector-image-icon-default-avatar-profile-icon-social-media-user-vector-image-209162840.jpg")
                                      : NetworkImage(
                                          '${dotenv.get('driverProfileUrl')}/$photo'))),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 25,
                            width: 25,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: whiteColor,
                                border:
                                    Border.all(color: whiteColor, width: 2.4),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                driverName.toString(),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: GoogleFonts.poppins(
                                    color: blackColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                carName.toString(),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: GoogleFonts.poppins(
                                    color: greyColor1,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 10),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                carColor.toString(),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: GoogleFonts.poppins(
                                    color: blackColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    "${double.tryParse(distance.toString())?.toStringAsFixed(1)} Km",
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
