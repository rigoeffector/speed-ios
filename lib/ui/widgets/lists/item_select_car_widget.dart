import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class SelectCarItemWidget extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String title;
  final String photo;
  final String plate;
  final String price;

  const SelectCarItemWidget(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId, required this.photo, required this.plate, required this.price });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: whiteColor ,
          borderRadius: BorderRadius.circular(10),
          border: id == selectedId ? Border.all(color: greenColor, width: 1.3) : Border.all(color: whiteColor2, width: 0)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                        height: 50,
                        width: 50,
                        margin: const EdgeInsets.all(10),
                        child: Image.asset(photo)),
                    Positioned(
                      left:0, 
                      top:0, child:  
                      selectedId == id ? Container(
                      height: 30,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: greenColor),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: whiteColor,
                        ),
                      ),
                    ): const Text( ""),)
                  ],
                ),

                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: selectedId == id ? primaryColor: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        plate,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w200,
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),

              ],
            ),
            Text(
              "\$ $price",
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: GoogleFonts.poppins(
                  color: selectedId == id ? primaryColor: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            )
          ],
        ),
      ),
    );
  }
}
