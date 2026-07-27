import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speed_ios/utils/colors.dart';

Future<void> showErrorAlert(String message, context) {
  return Flushbar(
    title: "Error",
    message: message,
    icon: const Icon(
      Icons.info_outline,
      size: 28.0,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.all(30),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
    reverseAnimationCurve: Curves.elasticInOut,
    forwardAnimationCurve: Curves.elasticInOut,
    backgroundColor: orangeColor,
  ).show(context);
}

Future<void> showSuccessAlert(String message, context) {
  return Flushbar(
    title: "Success",
    message: message,
    icon: const Icon(
      Icons.thumb_up,
      size: 28.0,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.all(30),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
    reverseAnimationCurve: Curves.elasticInOut,
    forwardAnimationCurve: Curves.elasticInOut,
    backgroundColor: greenColor,
  ).show(context);
}

void showMessage(String message, Color colors) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: greenColor,
      textColor: whiteColor,
      fontSize: 12.0);
}

void showErrorMessage(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: redColor,
      textColor: whiteColor,
      fontSize: 12.0);
}
