import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speed_ios/model/nearby_driver_model.dart';
import 'package:speed_ios/ui/widgets/drivers/driver.item.row.dart';

import '../../../utils/colors.dart';

class DriverProfileWidget extends StatefulWidget {
  List<NearbyDriverData> driverInformation;
  DriverProfileWidget({super.key, required this.driverInformation});

  @override
  State<DriverProfileWidget> createState() => _DriverProfileWidgetState();
}

class _DriverProfileWidgetState extends State<DriverProfileWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TextButton(
              onPressed: () {
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Text(
                  "Click here Back to searching",
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: GoogleFonts.poppins(
                      color: redColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              )),
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: widget.driverInformation!.length,
              // list item builder
              itemBuilder: (BuildContext ctx, index) {
                NearbyDriverData item = widget.driverInformation[index];
                return DriverItemRow(
                  driverId: '${item.id}',
                  driverName: '${item.driverName}',
                  driverPhone: '${item.driverPhone}',
                  carName: '${item.distance}',
                  carPlateNo: '${item.plateNumber}',
                  carColor: '${item.color}',
                  onTAp: () {},
                  distance: '4500',
                  photo: '',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
