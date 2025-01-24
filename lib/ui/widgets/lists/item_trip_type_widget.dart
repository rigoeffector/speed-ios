import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class TripTypeItem extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String title;

  const TripTypeItem(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 30,
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          color: whiteColor ,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: selectedId == id ? primaryColor: whiteColor, width: 0.9),
          boxShadow: const [
            BoxShadow(
              color: Color(0xffEDEDED),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1), // changes position of shadow
            )
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 90,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: GoogleFonts.poppins(
                  color: selectedId == id ? primaryColor: Colors.black45,
                  fontWeight: FontWeight.w300,
                  fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
