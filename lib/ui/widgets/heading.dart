import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/colors.dart';

class Heading extends StatelessWidget {
  final String title;
  final String subtitle;
  Heading({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: GoogleFonts.rubik(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              subtitle,
              textAlign: TextAlign.left,
              style: GoogleFonts.rubik(
                  color: blackColor, fontWeight: FontWeight.w300, fontSize: 12),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }
}
