import 'package:flutter/material.dart';import 'package:go_router/go_router.dart';
class SplashScreen extends StatefulWidget{const SplashScreen({super.key});@override State<SplashScreen> createState()=>_SplashScreenState();}
class _SplashScreenState extends State<SplashScreen>{@override void initState(){super.initState();Future.microtask(()=>context.go('/home'));}@override Widget build(BuildContext c)=>const Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.emoji_events,size:72),SizedBox(height:12),Text('World Cup Predictions')])));}
