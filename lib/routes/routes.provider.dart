import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_ios/routes/routes.names.dart';
import 'package:speed_ios/ui/screens/client.profile.dart';
import 'package:speed_ios/ui/screens/clients/set_destination.dart';
import 'package:speed_ios/ui/screens/clients/verify.phonenumber.dart';
import 'package:speed_ios/ui/screens/clients/rate_driver.dart';
import 'package:speed_ios/ui/screens/login.dart';
import 'package:speed_ios/ui/screens/splash.screen.dart';
import 'package:speed_ios/ui/screens/verify.otp.dart';
import 'package:speed_ios/ui/screens/settings.dart';
import 'package:speed_ios/ui/screens/welcome.dart';
import 'package:speed_ios/ui/screens/clients/home.dart';
import 'package:speed_ios/ui/screens/clients/list.my.requests.dart';
import 'package:speed_ios/ui/screens/clients/favorite_pickup_location.dart';
import 'package:speed_ios/ui/screens/clients/home_client.dart';

class AppNavigation {
  AppNavigation._();

  // Root navigator key for main app navigation
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Shell navigator key for nested navigation
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routerNeglect: true, // Prevents route killing

    // Global redirect to handle auth state
    redirect: (BuildContext context, GoRouterState state) {
      // Add your auth logic here
      return null;
    },

    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Material(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: splash,
            builder: (context, state) => Splash(key: state.pageKey),
            routes: [
              GoRoute(
                path: 'welcome',
                name: welcome,
                builder: (context, state) => Welcome(key: state.pageKey),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            name: login,
            builder: (context, state) => Login(key: state.pageKey),
          ),
          GoRoute(
            path: '/verify',
            name: verify,
            builder: (context, state) => VerifyPhoneNumber(key: state.pageKey),
          ),
          GoRoute(
            path: '/verifyOtp',
            name: verifyOtp,
            builder: (context, state) => VerifyOtpScreen(
              key: state.pageKey,
              type: state.uri.queryParameters['type'],
              otp: state.uri.queryParameters['otp'],
              phone: state.uri.queryParameters['phone'],
              clientId: state.uri.queryParameters['clientId'],
            ),
          ),
          GoRoute(
            path: '/clientProfile',
            name: clientProfile,
            builder: (context, state) => ClientProfileScreen(
              key: state.pageKey,
              clientId: state.uri.queryParameters['clientId'],
            ),
          ),
          GoRoute(
            path: '/home',
            name: home,
            builder: (context, state) {
              final refreshParam = state.uri.queryParameters['refresh'];
              return Home(
                key: ValueKey(refreshParam),
                refreshParam: refreshParam,
              );
            },
            routes: [
              GoRoute(
                path: 'myRequests',
                name: myRequests,
                builder: (context, state) {
                  final refreshParam = state.uri.queryParameters['refresh'];
                  return RequestsScreen(
                    key: ValueKey(refreshParam),
                    refreshParam: refreshParam,
                  );
                },
              ),
              GoRoute(
                path: 'profile',
                name: profile,
                builder: (context, state) => UserProfile(key: state.pageKey),
              ),
            ],
          ),
          GoRoute(
            path: '/clientDirections',
            name: clientDirections,
            builder: (context, state) => ClientDirections(
              key: state.pageKey,
              requestId: state.uri.queryParameters['requestId'],
              originLocation: state.uri.queryParameters['originLocation'],
              destinationLocation:
                  state.uri.queryParameters['destinationLocation'],
              clientNames: state.uri.queryParameters['clientNames'],
              clientPhone: state.uri.queryParameters['clientPhone'],
            ),
          ),
          GoRoute(
            path: '/complete',
            name: complete,
            builder: (context, state) => DriverRating(key: state.pageKey),
          ),
          GoRoute(
            path: '/myHistory',
            name: myHistory,
            builder: (context, state) => SetDestination(
              key: state.pageKey,
              userId: state.uri.queryParameters['userId'],
            ),
          ),
          GoRoute(
            path: '/myLocation',
            name: myLocation,
            builder: (context, state) => FavoritePickUpLocation(
              key: state.pageKey,
              clientId: state.uri.queryParameters['clientId'],
            ),
          ),
          // GoRoute(
          //   path: '/cancelRide',
          //   name: cancelRide,
          //   builder: (context, state) => CancelRequestScreen(
          //     key: state.pageKey,
          //     tripId: state.uri.queryParameters['tripId'],
          //     clientId: state.uri.queryParameters['clientId'],
          //     driverId: state.uri.queryParameters['driverId'],
          //     sourceLoc: state.uri.queryParameters['sourceLoc'],
          //     destinationLoc: state.uri.queryParameters['destinationLoc'],
          //   ),
          // ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Material(
      child: Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );

  // Navigation helper methods

  static void navigateToProfile(BuildContext context, String clientId) {
    context.safeGoNamed('/clientProfile?clientId=$clientId');
  }

  static void navigateToRefreshRequest(BuildContext context) {
    context.safeGoNamed(myRequests,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateToRefreshHome(BuildContext context) {
    context.safeGoNamed(home,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.safeGoNamed('/home');
    }
  }

  static Future<bool> handleWillPop(BuildContext context) async {
    // Check the current route name
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == '/home') {
      // Disable back press if the route is '/home'
      return false;
    }

    if (context.canPop()) {
      context.pop();
      return false;
    }
    return true;
  }
}

// Extension for easier navigation
extension NavigationExtension on BuildContext {
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go('/home');
    }
  }

  void safeGoNamed(String name, {Map<String, String>? params}) {
    try {
      if (params != null) {
        goNamed(name, queryParameters: params);
      } else {
        goNamed(name);
      }
    } catch (e) {
      go('/home');
    }
  }
}
