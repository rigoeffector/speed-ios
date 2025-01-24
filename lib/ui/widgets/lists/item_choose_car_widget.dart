import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class CarCategoryItem extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String title;
  final String photo;
  final String price;
  final String avalaible;

  const CarCategoryItem(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId, required this.photo, required this.price, required this.avalaible });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child:Container(
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        height: 100,
        width: 130,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height:70,
              width: 130,
              margin:  const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
              decoration: BoxDecoration(
                  color: id == selectedId ? primaryColor : whiteColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: id == selectedId ? primaryColor : whiteColor1, width: 1.6)
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 8),
                        child: Text(
                          "Available ",
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color:  id == selectedId ? whiteColor : blackColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 9),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, left: 4, right: 6),
                        child: Text(
                          " $avalaible",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color:  id == selectedId ? whiteColor : blackColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 10),
                        ),
                      ),

                    ],
                  ),
                  Center(
                     child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Image.asset("assets/images/$photo", height: 49,),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Padding(
                  padding: const EdgeInsets.only(top: 3.0, left: 8),
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color:  id == selectedId ? primaryColor : blackColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3.0, right: 8),
                  child: Text(
                    "\$$price",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: blackColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
