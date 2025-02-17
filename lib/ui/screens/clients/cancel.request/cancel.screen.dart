import 'package:speed_ios/routes/routes.provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speed_ios/api/cancel.service.dart';
import 'package:speed_ios/api/firebase.notification.service.dart';
import 'package:speed_ios/model/cancle.reason.model.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/states/cancel.request/cancel_request_bloc.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';
import 'package:speed_ios/ui/widgets/lists/item_cancel_row.dart';
import 'package:speed_ios/utils/colors.dart';

import '../../../../states/register.client/register_client_bloc.dart';
import '../../../../utils/notifiers.dart';

class CancelRequestScreen extends StatefulWidget {
  String? tripId;
  String? clientId;
  String? driverId;
  String? sourceLoc;
  String? destinationLoc;
  CancelRequestScreen(
      {super.key,
      this.tripId,
      this.clientId,
      this.driverId,
      this.sourceLoc,
      this.destinationLoc});

  @override
  State<CancelRequestScreen> createState() => _CancelRequestScreenState();
}

class _CancelRequestScreenState extends State<CancelRequestScreen> {
  CancelRequestBloc cancelRequestBloc =
      CancelRequestBloc(CancelRequestInitial(), CancelService());

  bool isCancelLoading = false;

  // FirebaseApi firebaseService = FirebaseApi();
  // final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    cancelReasonModel = CancelReasonModel();
    cancelRequestBloc = BlocProvider.of<CancelRequestBloc>(context);
  }

  // void sendDriverNotification(String driverId, String title, String msg) async {
  //   DocumentSnapshot snap =
  //       await _firestore.collection("driverTokens").doc(driverId).get();
  //   String token = snap['token'];

  //   firebaseService.sendPushNotification(
  //       title.toString(), msg.toString(), token);
  // }

  String? reasonDesc, selectedId;
  late CancelReasonModel cancelReasonModel;

  List<CancelReasonModel> reasons = [
    CancelReasonModel(id: "1", reason: "Changed plans, no longer need a ride."),
    CancelReasonModel(id: "2", reason: "Found alternative transportation."),
    CancelReasonModel(id: "3", reason: "Emergency came up, can't make it."),
    CancelReasonModel(id: "4", reason: "Driver ETA too long."),
    CancelReasonModel(
        id: "5", reason: "Going with a different ride-sharing service."),
    CancelReasonModel(id: "6", reason: "Uncomfortable with the vehicle type."),
    CancelReasonModel(id: "7", reason: "Decided to drive myself"),
    CancelReasonModel(id: "8", reason: "Changed destination, need to cancel.")
  ];

  // cancelRideRequested(String status) {
  //   CollectionReference collection = _firestore.collection('rideRequests');
  //   DocumentReference document = collection.doc(widget.clientId.toString());

  //   Map<String, Object> updatedLocationMap = {'status': status};

  //   document.update(updatedLocationMap);

  //   sendDriverNotification(
  //       widget.driverId.toString(),
  //       "Cancelled Client Request ",
  //       "Dear Driver, Your client request has been cancelled reasos: $reasonDesc , \nPick up location ${widget.sourceLoc.toString()} to ${widget.destinationLoc.toString()}");

  //   context
  //       .goNamed(home, queryParameters: {'userId': widget.clientId.toString()});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              context.safeGoNamed(home,
                  params: {'userId': widget.clientId.toString()});
            },
            icon: const Icon(Icons.arrow_back)),
        title: Text("Ride Request  Cancelation",
            style: GoogleFonts.poppins(
                fontSize: 16, color: whiteColor, fontWeight: FontWeight.w400)),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headingInfo(),
            cancelQuestionInfo(),
            BlocConsumer<CancelRequestBloc, CancelRequestState>(
              listener: (context, state) {
                if (state is CancelRequestError) {
                  showErrorAlert(state.message, context);
                  setState(() {
                    isCancelLoading = false;
                  });
                }
                if (state is CancelRequestLoading) {
                  setState(() {
                    isCancelLoading = true;
                  });
                }
                if (state is CancelRequestSuccess) {
                  setState(() {
                    isCancelLoading = false;
                  });
                  //sending request driver notification

                  // cancelRideRequested("2");
                }
              },
              builder: (context, state) {
                return MyButton(
                  title: "CANCEL RIDE REQUEST",
                  backgroundColor: primaryColor,
                  onTap: () {
                    cancelRequestBloc.add(HandleCancelRequestInformation(
                        requestId: widget.tripId.toString(),
                        feedback: "feedback"));
                  },
                  isLoading: isCancelLoading,
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget headingInfo() => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: primaryColorOverlay),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        width: MediaQuery.of(context).size.width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Why are you cancel your ride request",
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
                "We're  to see you cancel your ride , To help us improve, we have a few short questions for you before you leave.",
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w400)),
          ),
        ]),
      );

  Widget cancelQuestionInfo() => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: transparentColor),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        width: MediaQuery.of(context).size.width,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(reasons.length, (index) {
              CancelReasonModel item = reasons[index];
              return CancelItemRow(
                id: item.id.toString(),
                selectedId: selectedId.toString(),
                title: item.reason.toString(),
                onTap: () {
                  setState(() {
                    reasonDesc = item.reason.toString();
                    selectedId = item.id.toString();
                  });
                },
              );
            })),
      );
}
