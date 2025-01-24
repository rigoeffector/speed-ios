import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemSetting extends StatelessWidget {
  final String title;
  final String image;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final double size;
  final bool isLang;
  final Function()? onTap;
  const ItemSetting(
      {Key? key,
      required this.title,
      this.backgroundColor = primaryColorOverlay,
      required this.icon,
      required this.iconColor,
      required this.isLang,
      required this.image,
      this.size = 40,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  margin: const EdgeInsets.only(
                      top: 5, left: 8, right: 8, bottom: 9),
                  padding: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: whiteColor,
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0.0, 2.0),
                        color: Color(0xffEDEDED),
                        blurRadius: 3.0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            child: Icon(
                              icon,
                              color: primaryColor,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.rubik(
                                  color: blackColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Positioned(
                    right: 0,
                    child: isLang
                        ? Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: primaryColorOverlay, width: 2),
                                image: DecorationImage(
                                    image: ExactAssetImage(image),
                                    fit: BoxFit.cover)),
                          )
                        : Text(" "))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
