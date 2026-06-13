import 'package:flutter/material.dart';import '../utils/date_time_utils.dart';
class CountdownText extends StatelessWidget{final DateTime? target;const CountdownText({super.key,this.target});@override Widget build(BuildContext c)=>Text('Starts in ${DateTimeUtils.countdown(target)}',style:TextStyle(color:Theme.of(c).colorScheme.primary,fontWeight:FontWeight.w700));}
