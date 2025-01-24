import 'package:flutter/material.dart';

class MyPageRoute extends PageRouteBuilder{
  final Widget widget;

  MyPageRoute({required this.widget}):super(
      transitionDuration: Duration(seconds: 1),
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation, Widget child){
        animation = CurvedAnimation(parent: animation, curve: Curves.elasticInOut);
        return ScaleTransition(scale: animation, child: child, alignment: Alignment.center,);
      },
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation){
        return widget;
      }
  );
}