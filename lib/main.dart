import 'dart:async';
import 'dart:io';
import 'package:speed_ios/controllers/request_controller.dart';
import 'package:speed_ios/states/create.client_favorite.location/create_client_favorite_location_bloc.dart';
import 'package:speed_ios/states/get.favorite.location/get_client_favorite_location_bloc.dart';
import 'package:speed_ios/states/requests/active_request_bloc.dart';
import 'package:speed_ios/states/requests/create_request_bloc.dart';
import 'package:speed_ios/states/requests/fetch/received_sent_requests_bloc.dart';
import 'package:speed_ios/states/requests/update/update_sent_request_status_bloc.dart';
import 'package:speed_ios/states/update.profile/update_profile_bloc.dart';
import 'package:speed_ios/states/verify/verify_otp_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/api/cancel.service.dart';
import 'package:speed_ios/api/location.service.dart';
import 'package:speed_ios/routes/routes.provider.dart';
import 'package:speed_ios/states/available.driver.location/available_driver_location_bloc.dart';
import 'package:speed_ios/states/cancel.request/cancel_request_bloc.dart';
import 'package:speed_ios/states/client.profile.data/client_profile_bloc.dart';
import 'package:speed_ios/states/fetch.car.category/car_category_bloc.dart';
import 'package:speed_ios/states/nearby.driver/nearby_driver_bloc.dart';
import 'package:speed_ios/states/register.client/register_client_bloc.dart';
import 'package:speed_ios/states/update.client/update_client_bloc.dart';
import 'package:speed_ios/states/user.login/user_login_bloc.dart';
import 'package:speed_ios/utils/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'controllers/language_controller.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:speed_ios/api/firebase.notification.service.dart';


Future<void> main() async {
  if (kReleaseMode) {
    await dotenv.load(fileName: '.env');
  }
  if (kDebugMode) {
    await dotenv.load(fileName: '.env');
  }
  if (kProfileMode) {
    await dotenv.load(fileName: '.env');
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseApi().initNotifications();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  HttpOverrides.global = MyHttpOverrides();

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageController()),
      ],
      child: EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
          path:
              'assets/translations', // <-- change the path of the translation files
          fallbackLocale: const Locale('en', 'US'),
          useFallbackTranslations: true,
          child: Phoenix(child: MyApp(showHome: showHome)))));
}

class MyApp extends StatefulWidget {
  final bool showHome;
  const MyApp({Key? key, required this.showHome}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> requestLocationPermission() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('Current location: ${position.latitude}, ${position.longitude}');
  }

  @override
  void initState() {
    requestLocationPermission();
    _checkForAppUpdate();

    super.initState();
  }

  Future<void> _checkForAppUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Immediate Update
        await InAppUpdate.performImmediateUpdate();
        // _showUpdatePage();
      }
    } catch (e) {
      print('Failed to check for update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light, // For Android (dark icons)
        statusBarBrightness: Brightness.light));
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterClientBloc>(
            create: (_) =>
                RegisterClientBloc(RegisterClientLoading(), AuthService())),
        BlocProvider<UpdateClientBloc>(
            create: (_) =>
                UpdateClientBloc(UpdateClientInitial(), AuthService())),
        BlocProvider<CarCategoryBloc>(
            create: (_) =>
                CarCategoryBloc(CarCategoryLoading(), AuthService())),
        BlocProvider<UpdateSentRequestStatusBloc>(
            create: (_) => UpdateSentRequestStatusBloc(
                UpdateSentRequestStatusInitial(), AuthService())),
        BlocProvider<AvailableDriverLocationBloc>(
            create: (_) => AvailableDriverLocationBloc(LocationService())),
        BlocProvider<NearbyDriverBloc>(
            create: (_) =>
                NearbyDriverBloc(NearbyDriverInitial(), LocationService())),
        BlocProvider<CancelRequestBloc>(
            create: (_) =>
                CancelRequestBloc(CancelRequestInitial(), CancelService())),
        BlocProvider<ClientProfileBloc>(
            create: (_) =>
                ClientProfileBloc(ClientProfileInitial(), AuthService())),
        BlocProvider<UserLoginBloc>(
            create: (_) => UserLoginBloc(UserLoginInitial(), AuthService())),
        BlocProvider<CreateClientFavoriteLocationBloc>(
            create: (_) => CreateClientFavoriteLocationBloc(
                CreateClientFavoriteLocationInitial(), LocationService())),
        BlocProvider<GetClientFavoriteLocationBloc>(
            create: (_) => GetClientFavoriteLocationBloc(
                GetClientFavoriteLocationInitial(), LocationService())),
        BlocProvider<UpdateProfileBloc>(
            create: (_) =>
                UpdateProfileBloc(UpdateProfileInitial(), AuthService())),
        BlocProvider<CreateRequestBloc>(
            create: (_) =>
                CreateRequestBloc(CreateRequestInitial(), AuthService())),
        BlocProvider<ReceivedSentRequestsBloc>(
          create: (context) => ReceivedSentRequestsBloc(
            requestsRepository:
                RequestsRepository(), // Use the instance created above
          ),
        ),
        BlocProvider<VerifyOtpBloc>(
            create: (_) => VerifyOtpBloc(VerifyOtpInitial(), AuthService())),
        BlocProvider(
          create: (context) => ActiveRequestBloc(
            AuthService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: AppNavigation.router,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          for (var locale in supportedLocales) {
            if (locale.languageCode == deviceLocale?.languageCode &&
                locale.countryCode == deviceLocale?.countryCode) {
              return deviceLocale;
            }
          }
          return supportedLocales.first;
        },
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primaryColor: Color.fromARGB(255, 18, 170, 112),
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
