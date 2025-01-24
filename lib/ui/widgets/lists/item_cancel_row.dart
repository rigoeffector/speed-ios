import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class CancelItemRow extends StatelessWidget {
  final Function()? onTap;
  final String id, selectedId;
  final String title;
  final String? icon;

  const CancelItemRow(
      {super.key,
      required this.id,
      this.onTap,
      required this.title,
      required this.selectedId,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selectedId == id ? primaryColor : whiteColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selectedId == id
                  ? Icons.check_circle_outline
                  : Icons.circle_outlined,
              color: selectedId == id ? primaryColor : greyColor,
            ),
            SizedBox(
              width: 10,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Text(
                  title,
                  maxLines: 2,
                  softWrap: false,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: selectedId == id ? primaryColor : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
