import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class CityItem extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String title;

  const CityItem(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: whiteColor ,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xffEDEDED),
              spreadRadius: 2,
              blurRadius: 3,
              offset: Offset(0, 2), // changes position of shadow
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.place, color: selectedId == id ? primaryColor: Colors.grey ,size: 20,),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 172,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: GoogleFonts.poppins(
                        color: selectedId == id ? primaryColor: Colors.black45,
                        fontWeight: FontWeight.w300,
                        fontSize: 15),
                  ),
                )
              ],
            ),
            id == selectedId
                ? Container(
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: primaryColor),
              child: const Center(
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: whiteColor,
                ),
              ),
            )
                : Radio(
              value: id,
              groupValue: selectedId,
              activeColor: greenColor,
              onChanged: (val)=>onTap!(),
            )
          ],
        ),
      ),
    );
  }
}
