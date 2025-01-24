import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';
class SelectWidgetItem extends StatelessWidget {
  final String hint;
  final  Function() onTap;
  final bool isSelected;
  const SelectWidgetItem({Key? key, required this.hint, required this.onTap, required this.isSelected}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 9),
          margin: const EdgeInsets.symmetric(
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(width: 1.1, color: whiteColor1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 5, horizontal: 5),
                child: Text(hint,style: GoogleFonts.poppins(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w300,
                    fontSize: 12)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45,)
            ],
          ),
        ),
      ),
    );
  }
}
