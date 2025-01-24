import 'dart:async';
import 'dart:convert';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/requests/fetch/received_sent_requests_bloc.dart';
import 'package:speed_ios/states/requests/update/update_sent_request_status_bloc.dart';
import 'package:speed_ios/ui/widgets/buttons/icon_button_normal.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/notifiers.dart';

class RequestsScreen extends StatefulWidget {
  final String? refreshParam;

  const RequestsScreen({Key? key, this.refreshParam}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late ReceivedSentRequestsBloc receivedSentRequestsBloc;
  int? userId;
  UpdateSentRequestStatusBloc updateSentRequestStatusBloc =
      UpdateSentRequestStatusBloc(
          UpdateSentRequestStatusInitial(), AuthService());
  @override
  void initState() {
    super.initState();
    receivedSentRequestsBloc =
        BlocProvider.of<ReceivedSentRequestsBloc>(context);
    updateSentRequestStatusBloc =
        BlocProvider.of<UpdateSentRequestStatusBloc>(context);
    getCurrentUserInfo();
  }

  Color statusStr(String status) {
    if (status == 'APPROVED') {
      return primaryColor;
    } else if (status == 'REJECTED') {
      return Colors.red;
    } else if (status == 'PENDING') {
      return Colors.orange;
    } else if (status == 'CANCELLED') {
      return Colors.grey;
    } else {
      return Colors.black;
    }
  }

  Future<void> getCurrentUserInfo() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userJson = sharedPreferences.getString("currentUser");

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      setState(() {
        userId = userMap['id'];
      });

      // Now that userId is set, add the event to fetch requests
      if (userId != null) {
        receivedSentRequestsBloc
            .add(HandleFetchRequests(userId: userId!.toString()));
      }
    } else {
      // Handle the case where userJson is null
      print('User info not found in SharedPreferences');
    }
  }

  void showRequestDetails(BuildContext context, singleRequest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            expand: false, // Allows scrolling if the content exceeds the height
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                    color: whiteColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                // Adjust the height as needed
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          'Request Details',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListBody(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Request Type",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            color: blackColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 11),
                                      ),
                                      Text(
                                        singleRequest.requestType.toString(),
                                        maxLines: 2,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            color: blackColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 23),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Request Status",
                                        maxLines: 1,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            color: blackColor,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 11),
                                      ),
                                      Text(
                                        singleRequest.status.toString(),
                                        maxLines: 2,
                                        softWrap: false,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            color: statusStr(singleRequest
                                                .status
                                                .toString()),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 23),
                                      ),
                                    ],
                                  )
                                ]),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: whiteColor1,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 188, 188, 188)
                                          .withOpacity(0.1), // Shadow color
                                  spreadRadius: 2, // Spread effect
                                  blurRadius: 6, // Blur effect
                                  offset: const Offset(
                                      0, 3), // Horizontal and vertical offset
                                ),
                              ],
                            ),
                            child: ListTile(
                                title: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${singleRequest.motorBiker!.fname ?? "------"} ${singleRequest.motorBiker!.lname ?? "------"}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: primaryColor),
                                        ),
                                        Text(
                                          'Phone:  ${singleRequest.motorBiker!.phone ?? "------"}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 12),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: whiteColor1),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'Motor: ${singleRequest.motorBiker!.motorType.toString()}'),
                                          Text(
                                              'Plate: ${singleRequest.motorBiker!.plateNumber.toString()}'),
                                        ],
                                      ),
                                    )
                                  ],
                                )),
                          ),
                          destinationSetedWidget(
                              singleRequest.destinationLocation.toString(),
                              singleRequest.originLocation.toString()),
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  Widget destinationSetedWidget(
          String locationSelected, String myCurrentAddress) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        decoration: BoxDecoration(
            color: whiteColor, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width - 50,
                      margin: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                          color: whiteColor0,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.only(right: 10),
                            child: const Icon(
                              CupertinoIcons.placemark,
                              color: greyColor,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Origin location",
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    color: blackColor,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 11),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width - 160,
                                  child: Text(
                                    myCurrentAddress,
                                    maxLines: 2,
                                    softWrap: false,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        color: blackColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 50,
                      margin: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                          color: whiteColor0,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.only(right: 10),
                            child: const Icon(
                              CupertinoIcons.placemark,
                              color: greenColor,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Destination location",
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    color: blackColor,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 11),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width - 160,
                                  child: Text(
                                    locationSelected,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: primaryColor,
        title: const Text('My Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.safeGoNamed(home);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Handle request job action
              AppNavigation.navigateToRefreshRequest(context);
            },
            icon: const Icon(
              Icons.sync,
              color: Colors.yellow,
              size: 40,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: BlocConsumer<ReceivedSentRequestsBloc, ReceivedSentRequestsState>(
        listener: (context, state) {
          if (state is ReceivedSentRequestsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ReceivedSentRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReceivedSentRequestsSuccess) {
            var requests = state.userSentRequestsModel.data!;
            requests.sort((a, b) {
              if (a.status == "PENDING" && b.status != "PENDING") {
                return -1;
              } else if (a.status != "PENDING" && b.status == "PENDING") {
                return 1;
              } else {
                return 0;
              }
            });
            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      padding: const EdgeInsets.all(
                          20), // adjust padding for icon size
                      child: const Icon(
                        Icons.inbox, // use any icon you prefer
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16), // space between icon and text
                    Text(
                      'No requests found',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                      color: whiteColor,
                      border: Border.all(width: 1, color: greenColor),
                      borderRadius: BorderRadius.circular(10)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${requests[index].motorBiker!.fname} ${requests[index].motorBiker!.lname}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Request Type",
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: blackColor,
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11),
                                    ),
                                    Text(
                                      requests[index].requestType.toString(),
                                      maxLines: 2,
                                      softWrap: false,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: blackColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 23),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Request Status",
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: blackColor,
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11),
                                    ),
                                    Text(
                                      requests[index].status.toString(),
                                      maxLines: 2,
                                      softWrap: false,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: statusStr(requests[index]
                                              .status
                                              .toString()),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 23),
                                    ),
                                  ],
                                )
                              ]),
                        ),
                        Row(
                          children: [
                            Visibility(
                              visible: requests[index].status == "ONGOING",
                              child: MyIconButton(
                                backgroundColor: orangeColor,
                                titleColor: whiteColor,
                                title: 'View Map',
                                width: 100,
                                onTap: () {
                                  context
                                      .safeGoNamed(clientDirections, params: {
                                    'requestId': requests[index].id.toString(),
                                    'originLocation': requests[index]
                                        .originLocation
                                        .toString(),
                                    'destinationLocation': requests[index]
                                        .destinationLocation
                                        .toString(),
                                    'clientNames':
                                        '${requests[index].client!.fname} ${requests[index].client!.fname}',
                                    'clientPhone':
                                        '${requests[index].client!.phone}',
                                  });
                                },
                              ),
                            ),
                            MyIconButton(
                              backgroundColor: primaryColor,
                              titleColor: whiteColor,
                              title: 'View Details',
                              width: 100,
                              onTap: () async {
                                showRequestDetails(context, requests[index]);
                              },
                            ),
                            Visibility(
                              visible: requests[index].status == "PENDING",
                              child: BlocConsumer<UpdateSentRequestStatusBloc,
                                  UpdateSentRequestStatusState>(
                                listener: (context, state) {
                                  if (state is UpdateSentRequestStatusSuccess) {
                                    showSuccessAlert(
                                      state.updateSentRequestModel.message
                                          .toString(),
                                      context,
                                    );
                                    getCurrentUserInfo();
                                    // updateSentRequestStatusBloc.add(
                                    //     HandleUpdateStatus(
                                    //         requestId:
                                    //             request.id.toString(),
                                    //         status: 'REJECTED'));
                                  }
                                  if (state is UpdateSentRequestStatusError) {
                                    showErrorAlert(
                                        state.message.toString(), context);
                                  }
                                },
                                builder: (context, state) {
                                  return MyIconButton(
                                    backgroundColor: redColor,
                                    titleColor: whiteColor,
                                    title: 'Cancel',
                                    width: 100,
                                    onTap: () {
                                      _confirmAction(
                                        context,
                                        'Reject',
                                        'Are you sure you want to apprrejectove this request?',
                                        () {
                                          // Handle approve logic here
                                          _updateRequestStatus(
                                            index,
                                            'REJECTED',
                                            requests[index].id!.toInt(),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is ReceivedSentRequestsInitial) {
            return const Center(child: Text('No requests available.'));
          } else {
            return const Center(child: Text('Unexpected state.'));
          }
        },
      ),
      bottomSheet: Container(
        height: 40,
        child: Center(
          child: Text(
            "Powerd by Besoft & BePay ltd",
            style: GoogleFonts.poppins(
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _updateRequestStatus(int index, String newStatus, int requestId) {
    updateSentRequestStatusBloc.add(
        HandleUpdateStatus(requestId: requestId.toString(), status: newStatus));
  }

  void _confirmAction(BuildContext context, String action, String message,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action),
          content: Text(
            message,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Handle button press
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 20), // Padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                elevation: 0, // Shadow effect
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15, // Font size
                  fontWeight: FontWeight.bold, // Font weight
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: primaryColor, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 20), // Padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                elevation: 0, // Shadow effect
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
                onConfirm(); // Call the confirm callback
              },
              child: BlocBuilder<UpdateSentRequestStatusBloc,
                  UpdateSentRequestStatusState>(
                builder: (context, state) {
                  if (state is UpdateSentRequestStatusLaoding) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  return Text(
                    action,
                    style: const TextStyle(
                      fontSize: 15, // Font size
                      fontWeight: FontWeight.bold, // Font weight
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
