import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class CardHeaderTitle extends StatelessWidget {
  final String title;
  const CardHeaderTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
          color: primaryColorOverlay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          overflow: TextOverflow.fade,
          style: GoogleFonts.poppins(
              color: primaryColor, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
