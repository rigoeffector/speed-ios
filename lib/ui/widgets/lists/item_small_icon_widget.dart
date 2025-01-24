import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class IconOptionWidget extends StatelessWidget {
  final Function()? onTap;
  final IconData icon;
  final String title;

  const IconOptionWidget(
      {super.key,
        required this.icon,
        this.onTap,
        required this.title });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                  color: primaryColorOverlay1,
                  shape: BoxShape.circle
              ),
              child:  Center(
                child: Icon(icon, size: 18, color: primaryColor,),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: GoogleFonts.poppins(
                    color:  blackColor,
                    fontWeight: FontWeight.w300,
                    fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
