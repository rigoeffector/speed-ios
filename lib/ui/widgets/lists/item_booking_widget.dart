import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class BookingItem extends StatelessWidget {
  final Function()? onTap;
  final Function()? onTapCancel;
  final String? id, selectedId;
  final String? source;
  final String? destination;
  final String? price;
  final String? time;
  final String? date;
  final String? trip;
  final String? status;
  final String? referenceNo;
  final String? driverCategory;
  final String? driverName;
  final String? driverPhone;

  const BookingItem(
      {super.key,
      this.id,
      this.onTap,
      this.onTapCancel,
      this.selectedId,
      this.price,
      this.source,
      this.destination,
      this.status,
      this.driverCategory,
      this.driverName,
      this.driverPhone,
      this.time,
      this.referenceNo,
      this.trip,
      this.date});

  @override
  Widget build(BuildContext context) {
    String getStatusStr(status) {
      if (status == "1") {
        return "Completed";
      } else if (status == "2") {
        return "Cancelled";
      } else if (status == "3") {
        return "On MOving";
      } else {
        return "Pending";
      }
    }

    Color getStatusClr(status) {
      if (status == "1") {
        return greenColor;
      } else if (status == "2") {
        return redColor;
      } else if (status == "3") {
        return blueColor;
      } else {
        return orangeColor;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  width: MediaQuery.of(context).size.width - 25,
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xffEDEDED),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1), // changes position of shadow
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          "#$referenceNo",
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.poppins(
                              color: getStatusClr(status),
                              fontWeight: FontWeight.w500,
                              fontSize: 10),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: whiteColor,
                                        border: Border.all(
                                            color: status == "1"
                                                ? greenColor
                                                : primaryColor1,
                                            width: 2),
                                        shape: BoxShape.circle),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 5),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      border: Border.all(
                                          color: status == "1"
                                              ? greenColor
                                              : primaryColor,
                                          width: 1),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 5),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 5),
                                    child: Icon(
                                      Icons.place,
                                      color: status == "1"
                                          ? greenColor
                                          : primaryColor,
                                      size: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pickup location",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: status == "1"
                                                ? greenColor
                                                : Colors.black54,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 10),
                                      ),
                                      SizedBox(
                                          width: 230,
                                          child: Text(
                                            "$source",
                                            maxLines: 1,
                                            softWrap: false,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.fade,
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11),
                                          )),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Destination location ",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: status == "1"
                                                ? greenColor
                                                : primaryColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 10),
                                      ),
                                      SizedBox(
                                          width: 230,
                                          child: Text(
                                            "$destination",
                                            maxLines: 1,
                                            softWrap: false,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.fade,
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 11),
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(
                                Icons.check_circle_outlined,
                                color: getStatusClr(status),
                                size: 20,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  getStatusStr(status),
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.fade,
                                  style: GoogleFonts.poppins(
                                      color: getStatusClr(status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: greyColor,
                                  size: 29,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      Visibility(
                        visible: selectedId == id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: status == "1",
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: greenColor, width: 1)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              height: 37,
                                              width: 37,
                                              margin: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  image: const DecorationImage(
                                                      image: AssetImage(
                                                          "assets/images/avatar.jpg"))),
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: whiteColor,
                                                    border: Border.all(
                                                        color: whiteColor,
                                                        width: 2.4),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 130,
                                              child: Text(
                                                "$driverName",
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.fade,
                                                style: GoogleFonts.poppins(
                                                    color: blackColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 130,
                                              child: Text(
                                                "$driverPhone",
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.fade,
                                                style: GoogleFonts.poppins(
                                                    color: greenColor,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        FlutterPhoneDirectCaller.callNumber(
                                            driverPhone!);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        decoration: const BoxDecoration(
                                            color: primaryColorOverlay,
                                            shape: BoxShape.circle),
                                        child: const Center(
                                          child: Icon(
                                            Icons.call_rounded,
                                            size: 20,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 6),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: MediaQuery.of(context).size.width - 50,
                              decoration: BoxDecoration(
                                  color: whiteColor1,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Details",
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.fade,
                                    style: GoogleFonts.poppins(
                                        color: greyColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Price : ",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: greyColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 10),
                                      ),
                                      SizedBox(
                                          width: 200,
                                          child: Text(
                                            "\$$price",
                                            maxLines: 1,
                                            softWrap: false,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.fade,
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 11),
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Date : ",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: greyColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 10),
                                      ),
                                      SizedBox(
                                          width: 200,
                                          child: Text(
                                            "$date",
                                            maxLines: 1,
                                            softWrap: false,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.fade,
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 11),
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Time : ",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.fade,
                                        style: GoogleFonts.poppins(
                                            color: greyColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 10),
                                      ),
                                      SizedBox(
                                          width: 200,
                                          child: Text(
                                            "$time",
                                            maxLines: 1,
                                            softWrap: false,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.fade,
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 11),
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Visibility(
                          visible: status == "0",
                          child: TextButton(
                              onPressed: onTapCancel,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                      "Cancel Trip",
                                      style:
                                          GoogleFonts.poppins(color: redColor),
                                    ),
                                  ),
                                ],
                              )))
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 40,
                  top: 40,
                  child: Container(
                    width: 6,
                    height: 30,
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                        color: whiteColor0,
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(80))),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 40,
                  top: 40,
                  child: Container(
                    width: 6,
                    height: 30,
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                        color: whiteColor0,
                        borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(80))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
