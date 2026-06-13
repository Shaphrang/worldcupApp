import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
class WorldCupPredictionsApp extends StatelessWidget{const WorldCupPredictionsApp({super.key});@override Widget build(BuildContext context)=>MaterialApp.router(title:'World Cup Predictions',theme:AppTheme.dark,routerConfig:appRouter,debugShowCheckedModeBanner:false);}
