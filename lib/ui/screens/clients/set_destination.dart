import 'dart:convert';

import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:speed_ios/controllers/home_controller.dart';
import 'package:speed_ios/model/booking_history_model.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../api/auth.service.dart';
import '../../../api/http_request.dart';
import '../../../model/auth/client.profile.model.dart';
import '../../../model/my_trip_model.dart';
import '../../../model/user_model.dart';
import '../../../states/client.profile.data/client_profile_bloc.dart';
import '../../widgets/lists/item_booking_widget.dart';

class SetDestination extends StatefulWidget {
  String? userId;
  SetDestination({Key? key, required this.userId}) : super(key: key);

  @override
  State<SetDestination> createState() => _SetDestinationState();
}

class _SetDestinationState extends State<SetDestination> {
  ClientProfileBloc _profileBloc =
      ClientProfileBloc(ClientProfileInitial(), AuthService());

  final controller = HomeController();

  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  late ClientData user;
  HttpService httpService = HttpService();
  String? clientId;
  int selectedTab = 2;
  List<BookingModel> myBooking = [];
  List<MyTripModel> myTrip = [];
  BookingModel? selectedBooking;
  String? selectedTripId;
  MyTripModel? selectedTrip;

  @override
  void initState() {
    _profileBloc = BlocProvider.of<ClientProfileBloc>(context);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _profileBloc
        .add(FetchAllClientInformation(clientId: widget.userId.toString()));

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(AppBar().preferredSize.height),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Visibility(
              visible: selectedTab == 1,
              child: Column(
                children: [
                  myTrip.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/images/no_result.png"),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Sorry; No Records Found",
                                    style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 17)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9.0, horizontal: 15),
                              child: Text("List of Trip ",
                                  style: GoogleFonts.poppins(
                                      color: greyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17)),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(myTrip.length,
                                  growable: true, (index) {
                                MyTripModel item = myTrip[index];
                                return BookingItem(
                                  id: '${item.id}',
                                  selectedId: selectedTrip != null
                                      ? selectedTrip!.id!
                                      : "",
                                  source: "${item.source}",
                                  destination: "${item.destination}",
                                  time: " ${item.updatedAt}",
                                  date: " ${item.createdAt}",
                                  status: "${item.status}",
                                  price: "${item.tripPrice}",
                                  trip: "${item.vehiType}",
                                  driverCategory: "${item.clientId}",
                                  driverPhone: "${item.tripType}",
                                  driverName: "${item.tripType}",
                                  referenceNo: "${item.tripType}",
                                  onTap: () {
                                    setState(() {
                                      selectedTrip = item;
                                    });
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            Visibility(
              visible: selectedTab == 2,
              child: Column(
                children: [
                  BlocConsumer<ClientProfileBloc, ClientProfileState>(
                    listener: (context, state) {},
                    builder: (context, state) {
                      if (state is ClientProfileLoading) {
                        return Center(
                          child: Text("Loading"),
                        );
                      }
                      if (state is ClientProfileSuccess) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9.0, horizontal: 15),
                              child: Text("List of Pending ",
                                  style: GoogleFonts.poppins(
                                      color: greyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17)),
                            ),
                            // Column(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   crossAxisAlignment: CrossAxisAlignment.center,
                            //   children: List.generate(
                            //       state.clientProfileModel.requestsData!.length,
                            //       growable: true, (index) {
                            //     RequestsData item = state
                            //         .clientProfileModel.requestsData![index];
                            //     return BookingItem(
                            //       id: '${item.id}',
                            //       selectedId: selectedTripId,
                            //       source: "${item.source}",
                            //       destination: "${item.destination}",
                            //       time: " ${item.createdAt}",
                            //       date: " ${item.createdAt}",
                            //       status: "${item.status}",
                            //       price: "${item.tripPrice}",
                            //       trip: "${item.tripType}",
                            //       driverCategory: "${item.clientId}",
                            //       driverPhone: " 0788********",
                            //       driverName: "Test Driver",
                            //       referenceNo: "XXXXXXXXXSXS",
                            //       onTap: () {
                            //         setState(() {
                            //           selectedTripId = item.id.toString();
                            //         });
                            //       },
                            //       onTapCancel: () {
                            //         context
                            //             .goNamed(cancelRide, queryParameters: {
                            //           'tripId': item.id.toString(),
                            //           'clientId': item.clientId.toString(),
                            //           'driverId': item.clientId.toString(),
                            //           'sourceLoc': item.source.toString(),
                            //           'destinationLoc':
                            //               item.destination.toString(),
                            //         });
                            //       },
                            //     );
                            //   }),
                            // ),
                          ],
                        );
                      }

                      return Text("");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _appBar(height) => PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, height + 58),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/back.jpg"),
                      fit: BoxFit.none)),
            ), //
            Container(
              height: height + 84,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: whiteColor2), // Background
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 35),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            context.safeGoNamed(home, params: {
                              'userId': widget.userId.toString()
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: blackColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9.0),
                          child: Text("History",
                              style: GoogleFonts.poppins(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17)),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.settings,
                              color: whiteColor2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                        color: whiteColor1,
                        borderRadius: BorderRadius.circular(33)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedTab = 2;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 5),
                              decoration: BoxDecoration(
                                  color: selectedTab == 2
                                      ? primaryColor
                                      : whiteColor1,
                                  borderRadius: BorderRadius.circular(29)),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: selectedTab == 2
                                          ? whiteColor
                                          : greyColor,
                                      size: 18,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 10),
                                      child: Text(
                                        "My Pending",
                                        style: GoogleFonts.poppins(
                                            color: selectedTab == 2
                                                ? whiteColor
                                                : greyColor,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedTab = 1;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 5),
                              decoration: BoxDecoration(
                                  color: selectedTab == 1
                                      ? primaryColor
                                      : whiteColor1,
                                  borderRadius: BorderRadius.circular(29)),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email,
                                      color: selectedTab == 1
                                          ? whiteColor1
                                          : greyColor,
                                      size: 18,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 10),
                                      child: Text(
                                        "My Trip",
                                        style: GoogleFonts.poppins(
                                            color: selectedTab == 1
                                                ? whiteColor
                                                : greyColor,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), // Required some widget in between to float AppBar
          ],
        ),
      );
}
