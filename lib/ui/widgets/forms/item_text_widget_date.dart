import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInputFieldDate extends StatelessWidget {
  final TextEditingController code;
  final String hint;
  final Function() onTap;
  final bool readyOnly;

  TextInputFieldDate(this.code, this.hint, this.onTap, this.readyOnly);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.0, color: whiteColor1)),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: TextField(
          readOnly: readyOnly,
          textAlign: TextAlign.left,
          keyboardType: TextInputType.text,
          controller: code,
          cursorColor: Theme.of(context).primaryColor,
          onTap: onTap,
          decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              border: InputBorder.none,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12.0, fontWeight: FontWeight.w300))),
    );
  }
}
