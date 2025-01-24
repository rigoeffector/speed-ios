import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';


class ItemRowProfile extends StatelessWidget {
  final String title;
  final String image;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final double size;
  final bool isLang;
  final Function()? onTap;
  const ItemRowProfile(
      {Key? key,
        required this.title,
        this.backgroundColor = whiteColor,
        required this.icon,
        required this.iconColor,
        required this. isLang,
        required this.image,
        this.size = 40, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 5, left: 1, right: 1, bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: size / 2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rubik(
                          color: greyColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                    ),

                  ],
                )
              ],
            ),
            isLang ?
            Container( width: 30, height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColorOverlay1, width: 2),
                  image: DecorationImage(
                      image: ExactAssetImage(image),
                      fit: BoxFit.cover)
              ),
            )
                :
            const Text("")
          ],
        ),
      ),
    );
  }
}