import 'package:flutter/material.dart';

class PinInfo {
  final int number;
  final String name;
  final String function;
  final String mode; // INPUT/OUTPUT/ANALOG_IN/ANALOG_OUT
  final String pull; // NONE/PULLUP/PULLDOWN

  PinInfo({
    required this.number,
    required this.name,
    required this.function,
    required this.mode,
    required this.pull,
  });

  factory PinInfo.fromJson(Map<String, dynamic> json) => PinInfo(
        number: json['number'],
        name: json['name'],
        function: json['function'],
        mode: json['mode'],
        pull: json['pull'],
      );
}
