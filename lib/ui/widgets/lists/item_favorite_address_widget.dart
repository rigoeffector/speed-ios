import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class FavoriteAddress extends StatelessWidget {
  final Function()? onTap;
  final String id, selectedId;
  final String title;
  final String? phone;
  final String? address;
  final String? lat;
  final String? lng;
  final String? icon;

  const FavoriteAddress(
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
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/$icon",
                height: 30,
                width: 30,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 8),
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.fade,
                      style: GoogleFonts.poppins(
                          color: selectedId == id ? primaryColor : primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 17,
                      color: Colors.black45,
                    ),
                    SizedBox(
                      width: 240,
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
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
