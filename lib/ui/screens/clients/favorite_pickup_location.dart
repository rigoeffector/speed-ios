import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:speed_ios/ui/widgets/buttons/button.dart';

import '../../../api/http_request.dart';
import '../../../api/location.service.dart';
import '../../../controllers/home_controller.dart';
import '../../../model/client.favorite.location.model.dart';
import '../../../model/pickup_location_model.dart';
import '../../../model/user_model.dart';
import '../../../states/create.client_favorite.location/create_client_favorite_location_bloc.dart';
import '../../../states/get.favorite.location/get_client_favorite_location_bloc.dart';
import '../../../utils/colors.dart';
import '../../../utils/notifiers.dart';
import '../../widgets/forms/item_text_widget_normal.dart';
import '../../widgets/forms/phone_text_input.dart';
import '../../widgets/lists/item_favorite_address_widget.dart';

class FavoritePickUpLocation extends StatefulWidget {
  String? clientId;
  FavoritePickUpLocation({Key? key, this.clientId}) : super(key: key);

  @override
  State<FavoritePickUpLocation> createState() => _FavoritePickUpLocationState();
}

class _FavoritePickUpLocationState extends State<FavoritePickUpLocation> {
  CreateClientFavoriteLocationBloc clientFavoriteLocationBloc =
      CreateClientFavoriteLocationBloc(
          CreateClientFavoriteLocationInitial(), LocationService());

  GetClientFavoriteLocationBloc getFavoriteLocationBloc =
      GetClientFavoriteLocationBloc(
          GetClientFavoriteLocationInitial(), LocationService());
  final controller = HomeController();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  late ClientData user;
  HttpService httpService = HttpService();
  String? clientId;
  bool isAddNew = false;
  bool isSubmitting = false;
  bool isLocationAvailable = false;
  List<PickUpLocationModel> myBooking = [];
  PickUpLocationModel? selectedTrip;

  Position? currentPosition;
  var geoLocator = Geolocator();
  String myCurrentAddress = "";
  double sLat = 0.0;
  double sLng = 0.0;

  void _onSearchPickUp() async {
    var place = await PlacesAutocomplete.show(
        offset: 0,
        radius: 50,
        strictbounds: false,
        region: "tz",
        context: context,
        mode: Mode.overlay,
        apiKey: dotenv.get('apiKey'),
        types: [],
        decoration: InputDecoration(
            hintText: "What's your pickup location",
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: InputBorder.none,
            hintStyle: GoogleFonts.poppins(
                fontSize: 13.0, fontWeight: FontWeight.w300)),
        components: [
          Component(Component.country, 'rw'),
          Component(Component.country, 'tz')
        ],
        hint: "What's your pickup ",
        onError: (e) {
          if (kDebugMode) {
            print("ERRORS ${e.predictions}");
          }
        });
    if (place != null) {
      final plist = GoogleMapsPlaces(
        apiKey: dotenv.get('apiKey'),
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      String placeid = place.placeId ?? "0";
      final detail = await plist.getDetailsByPlaceId(placeid);
      final geometry = detail.result.geometry!;
      final lat = geometry.location.lat;
      final lang = geometry.location.lng;
      // calculate distance

      setState(() {
        isLocationAvailable = true;
        sLat = lat;
        sLng = lang;
        myCurrentAddress = place.description.toString();
      });
    }
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
 
  }

  @override
  void initState() {
    clientFavoriteLocationBloc =
        BlocProvider.of<CreateClientFavoriteLocationBloc>(context);
    getFavoriteLocationBloc =
        BlocProvider.of<GetClientFavoriteLocationBloc>(context);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    getFavoriteLocationBloc
        .add(FetchFavoriteLocationEvent(clientId: widget.clientId.toString()));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(AppBar().preferredSize.height),
        body: BlocConsumer<GetClientFavoriteLocationBloc,
            GetClientFavoriteLocationState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is GetClientFavoriteLocationLoading) {
              return const Center(
                child: SpinKitDoubleBounce(
                  color: primaryColor,
                  size: 40,
                ),
              );
            }
            if (state is GetClientFavoriteLocationSuccess) {
              return SingleChildScrollView(
                child: state.model.addressRecords!.isEmpty
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(
                            state.model.addressRecords!.length,
                            growable: true, (index) {
                          AddressRecords item =
                              state.model.addressRecords![index];
                          return FavoriteAddress(
                            id: "${item.id}",
                            selectedId: "",
                            title: "${item.title}",
                            address: "${item.address}",
                            phone: "${item.phone}",
                            lat: '${item.latitude}',
                            lng: "${item.longitude}",
                            icon: 'home.png',
                            onTap: () {
                              setState(() {});
                            },
                          );
                        }),
                      ),
              );
            }
            return const Text("");
          },
        ),
        bottomSheet: isAddNew
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 400,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  color: whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xffada8a8),
                      spreadRadius: 5,
                      blurRadius: 4,
                      offset: Offset(4, 5), // changes position of shadow
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 10),
                          child: Text(
                            "Pickup Location",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              _onSearchPickUp();
                            },
                            child: Text(
                              "Change Pickup",
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.fade,
                              style: GoogleFonts.poppins(
                                  color: blueColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12),
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 300,
                      child: ListView(
                        children: [
                          TextInputFieldNormal(nameController, "Location name"),
                          TextInputFieldPhone(phoneController, "Phone number"),
                          isLoading
                              ? const SpinKitThreeBounce(
                                  color: primaryColor1,
                                )
                              : Visibility(
                                  visible: !isLocationAvailable,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18.0, vertical: 10),
                                    child: Text(
                                      "Please click + get location on button bellow to pick coordinate",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          color: greyColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300),
                                    ),
                                  ),
                                ),
                          Visibility(
                              visible: isLocationAvailable,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: greenColor, width: 1)),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.check_circle,
                                          color: greenColor),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 260,
                                          child: Text(myCurrentAddress,
                                              // overflow: TextOverflow.fade
                                              style: GoogleFonts.poppins(
                                                  color: greenColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400)),
                                        ),
                                        Visibility(
                                          visible: false,
                                          child: Text(
                                              "Latitude: $sLat - Longitude : $sLng ",
                                              style: GoogleFonts.poppins(
                                                  color: greyColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w300)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                          
                          
                              });
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: blueColor,
                                ),
                                Text("Click here to Get Location")
                              ],
                            ),
                          ),
                          BlocConsumer<CreateClientFavoriteLocationBloc,
                              CreateClientFavoriteLocationState>(
                            listener: (context, state) {
                              if (state is CreateClientFavoriteLocationError) {
                                showErrorAlert(
                                    state.message.toString(), context);

                                setState(() {
                                  isSubmitting = false;
                                });
                              }

                              if (state
                                  is CreateClientFavoriteLocationLoading) {
                                setState(() {
                                  isSubmitting = true;
                                });
                              }

                              if (state
                                  is CreateClientFavoriteLocationSuccess) {
                                setState(() {
                                  isAddNew = false;
                                  isLocationAvailable = false;
                                  isLoading = false;
                                  isSubmitting = false;
                                });
                              }
                            },
                            builder: (context, state) {
                              return MyButton(
                                title: "Save Location",
                                isLoading: isSubmitting,
                                backgroundColor: primaryColor,
                                onTap: () {
                                  if (isLocationAvailable &&
                                      nameController.text.isNotEmpty) {
                                    clientFavoriteLocationBloc.add(
                                        HandleCreateLocationEvent(
                                            latitude: sLat.toString(),
                                            longitude: sLng.toString(),
                                            clientId:
                                                widget.clientId.toString(),
                                            title:
                                                nameController.text.toString(),
                                            address:
                                                myCurrentAddress.toString(),
                                            phone: phoneController.text
                                                .toString()));
                                  } else {
                                    showErrorAlert(
                                        "Please get address and fill field bellow first ",
                                        context);
                                  }
                                },
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isAddNew = false;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.close,
                                  color: orangeColor,
                                ),
                                Text(
                                  "Close",
                                  style:
                                      GoogleFonts.poppins(color: orangeColor),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const Text(""));
  }

  _appBar(height) => PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, height + 30),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                  color: primaryColor,
                  image: DecorationImage(
                      image: AssetImage("assets/images/back.jpg"),
                      fit: BoxFit.none)),
            ), //
            Container(
              height: height + 60,
              width: MediaQuery.of(context).size.width,
              decoration:
                  const BoxDecoration(color: primaryColor), // Background
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: whiteColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9.0),
                      child: Text("My locations ",
                          style: GoogleFonts.poppins(
                              color: whiteColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 17)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isAddNew = true;
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            color: orangeColor,
                          ),
                          Text(
                            "Add New",
                            style: GoogleFonts.poppins(color: orangeColor),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ), // Required some widget in between to float AppBar
          ],
        ),
      );
}
