//lib\core\widgets\countdown_text.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/date_time_utils.dart';

class CountdownText extends StatefulWidget {
  final DateTime? target;
  final String prefix;

  const CountdownText({
    super.key,
    this.target,
    this.prefix = 'Starts in',
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix} ${DateTimeUtils.countdown(widget.target)}',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}