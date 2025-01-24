import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyIconButton extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final IconData? icon;
  final Color backgroundColor;
  final Function()? onTap;
  final double? width;
  const MyIconButton({Key? key, required this.title, this.onTap, required this.backgroundColor, this.width, this.titleColor,   this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10)
          ),
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Text(
                title,
                style: GoogleFonts.poppins(
                    color: titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
