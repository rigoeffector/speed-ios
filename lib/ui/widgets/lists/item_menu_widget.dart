import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class MenuItem extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String title;
  final IconData icon;

  const MenuItem(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId, required this.icon });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 47,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selectedId == id ? whiteColor0: primaryColor
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(icon, color: selectedId == id ? whiteColor: whiteColor ,size: 20,),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 262,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: GoogleFonts.poppins(
                        color: selectedId == id ? whiteColor: whiteColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
