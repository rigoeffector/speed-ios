import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class FavoritePickUpAddress extends StatelessWidget {
  final Function()? onTap;
  final String id, selectedId;
  final String title;
  final String? address;
  final String? phone;
  final String? lat;
  final String? lng;
  final String? icon;

  const FavoritePickUpAddress(
      {super.key,
      required this.id,
      this.onTap,
      required this.title,
      required this.selectedId,
      this.address,
      this.icon,
      this.lat,
      this.lng,
      this.phone});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
              color: selectedId == id ? primaryColor : whiteColor, width: 0.9),
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
            Image.asset(
              "assets/images/$icon",
              height: 20,
              width: 20,
            ),
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.fade,
                  style: GoogleFonts.poppins(
                      color: selectedId == id ? primaryColor : Colors.black45,
                      fontWeight: FontWeight.w500,
                      fontSize: 11),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.place,
                  size: 12,
                  color: Colors.black45,
                ),
                SizedBox(
                  width: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      address!,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.fade,
                      style: GoogleFonts.poppins(
                          color: Colors.black45,
                          fontWeight: FontWeight.w300,
                          fontSize: 10),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
