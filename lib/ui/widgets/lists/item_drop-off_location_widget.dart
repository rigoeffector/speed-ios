import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class DropOffLocationItemWidget extends StatelessWidget {
  final Function()? onTapRemove;
  final String id;
  final String title;

  const DropOffLocationItemWidget(
      {super.key,
        required this.id,
        required this.title,
        this.onTapRemove,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      decoration: BoxDecoration(
        color: primaryColorOverlay1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                child: const Center(
                  child: Icon(
                    Icons.place_outlined,
                    color: primaryColor,
                    size: 19,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 220,
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: blackColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 12),
                      )),
                  SizedBox(
                      width: 220,
                      child: Text(
                        "Cordinate: $id",
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontWeight: FontWeight.w200,
                            fontSize: 10),
                      )),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: onTapRemove,
            child: Center(
              child: Icon(Icons.remove_circle_outline_rounded, color: redColor, size: 22,),
            ),
          )
        ],
      ),
    );
  }
}
