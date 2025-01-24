import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';

class MyButton extends StatefulWidget {
  final String title;
  final Color? titleColor;
  final Color backgroundColor;
  final Function()? onTap;
  final bool isLoading;
 
  const MyButton(
      {Key? key,
      required this.title,
      this.onTap,
      required this.isLoading,
      required this.backgroundColor,
      this.titleColor, })
      : super(key: key);

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        height: 45,
        width: MediaQuery.of(context).size.width ,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.isLoading
                ? const SpinKitThreeBounce(
                    color: whiteColor,
                    size: 20,
                  )
                : Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                        color: whiteColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
          ],
        ),
      ),
    );
  }
}
