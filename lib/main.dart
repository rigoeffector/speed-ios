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
import 'package:firebase_database/firebase_database.dart';
 
import 'firebase_options.dart';

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
   await _initializeFirebase();
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
          path: 'assets/translations',
          fallbackLocale: const Locale('en', 'US'),
          useFallbackTranslations: true,
          child: Phoenix(child: MyApp(showHome: showHome)))));
}
Future<void> _initializeFirebase() async {
  if (kDebugMode) {
    print('\n🔥 Initializing Firebase...');
  }

  try {
    // Initialize Firebase only if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ Firebase already initialized');
      }
    }

    // Get database instance and verify URL
    final database = FirebaseDatabase.instance;
    final databaseUrl = database.databaseURL;
    
    if (kDebugMode) {
      print('📍 Database URL: $databaseUrl');
    }

    if (databaseUrl == null || databaseUrl.isEmpty) {
      if (kDebugMode) {
        print('❌ ERROR: Database URL is null or empty!');
        print('   Please check firebase_options.dart');
      }
      return;
    }

    // Enable persistence for offline support
    try {
      database.setPersistenceEnabled(true);
      database.setPersistenceCacheSizeBytes(10000000); // 10MB
      
      if (kDebugMode) {
        print('✅ Firebase persistence enabled (10MB cache)');
        database.setLoggingEnabled(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Persistence already enabled: $e');
      }
    }

    // Test connection
    if (kDebugMode) {
      print('🔍 Testing Firebase connection...');
      _testFirebaseConnection();
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase initialization error: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }
}

Future<void> _testFirebaseConnection() async {
  try {
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    
    // Set a timeout for the connection test
    final subscription = connectedRef.onValue.timeout(
      const Duration(seconds: 10),
    ).listen(
      (event) {
        final connected = event.snapshot.value as bool? ?? false;
        if (kDebugMode) {
          print(connected 
            ? '✅ Firebase Realtime Database: CONNECTED' 
            : '🔴 Firebase Realtime Database: DISCONNECTED'
          );
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Firebase connection test error: $error');
        }
      },
    );

    // Clean up after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      subscription.cancel();
    });
  } catch (e) {
    if (kDebugMode) {
      print('❌ Connection test failed: $e');
    }
  }
}
class MyApp extends StatefulWidget {
  final bool showHome;
  const MyApp({Key? key, required this.showHome}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitializing = true;
  bool _updateCheckComplete = false;

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

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Current location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Run location permission and update check in parallel
      await Future.wait([
        requestLocationPermission(),
        _checkForAppUpdate(),
      ]);
    } catch (e) {
      print('Error during app initialization: $e');
    } finally {
      // Mark initialization as complete
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _updateCheckComplete = true;
        });
      }
    }
  }

  Future<void> _checkForAppUpdate() async {
    // Only check for updates on Android
    if (!Platform.isAndroid) {
      print('Update check skipped: Not on Android platform');
      return;
    }

    try {
      print('Checking for app updates...');
      
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      print('Update availability: ${updateInfo.updateAvailability}');

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        print('Update available - initiating immediate update');
        
        // Check if immediate update is allowed
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          print('Immediate update completed');
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Optional: Handle flexible update if immediate is not allowed
          print('Flexible update available but immediate update not allowed');
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        print('No update available');
      }
    } on PlatformException catch (e) {
      print('Platform exception during update check: ${e.code} - ${e.message}');
    } catch (e) {
      print('Failed to check for update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light));

    // Show loading screen while initializing
    if (_isInitializing) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: primaryColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'Checking for updates...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Proceed with normal app initialization after update check
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterClientBloc>(
            create: (_) =>
                RegisterClientBloc(const RegisterClientLoading(), AuthService())),
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
            requestsRepository: RequestsRepository(),
          ),
        ),
        BlocProvider<VerifyOtpBloc>(
            create: (_) => VerifyOtpBloc(VerifyOtpInitial(), AuthService())),
        BlocProvider(
          create: (context) => ActiveRequestBloc(AuthService()),
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
          primaryColor: primaryColor,
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