import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/colors.dart';

class ItemUserWidget extends StatelessWidget {
  final Function()? onTap;
  final String id,selectedId;
  final String icon;
  final String title;

  const ItemUserWidget(
      {super.key,
        required this.id,
        this.onTap,
        required this.title, required this.selectedId, required this.icon });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: whiteColor ,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: id == selectedId ? primaryColor : whiteColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0xffEDEDED),
                spreadRadius: 2,
                blurRadius: 3,
                offset: Offset(0, 2), // changes position of shadow
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  icon,
                  height: 50, width: 50,
                  color: selectedId == id ? primaryColor: Colors.grey,
                )
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width - 172,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: GoogleFonts.poppins(
                      color: selectedId == id ? primaryColor: Colors.black45,
                      fontWeight: FontWeight.w300,
                      fontSize: 15),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
