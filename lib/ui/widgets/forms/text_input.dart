import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInputFieldPassword extends StatelessWidget {
  final TextEditingController pass;
  final String hint;

  TextInputFieldPassword(this.pass, this.hint);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: whiteColor1, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: TextField(
          textAlign: TextAlign.left,
          keyboardType: TextInputType.text,
          controller: pass,
          obscureText: true,
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
