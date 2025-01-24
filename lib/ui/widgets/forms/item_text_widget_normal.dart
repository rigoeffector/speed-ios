import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInputFieldNormal extends StatelessWidget {
  final TextEditingController code;
  final String hint;

  TextInputFieldNormal(this.code, this.hint);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.1, color: whiteColor1)),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: TextField(
          textAlign: TextAlign.left,
          keyboardType: TextInputType.text,
          controller: code,
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              border: InputBorder.none,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12.0, fontWeight: FontWeight.w300))),
    );
  }
}
