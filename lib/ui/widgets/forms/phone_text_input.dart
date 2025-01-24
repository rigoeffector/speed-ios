import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInputFieldPhone extends StatelessWidget {
  final TextEditingController code;
  final String hint;

  TextInputFieldPhone(this.code, this.hint);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: whiteColor,
          border: Border.all(width: 1.1, color: whiteColor1),
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: TextField(
          textAlign: TextAlign.left,
          keyboardType: TextInputType.phone,
          controller: code,
          maxLength: 10,
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
