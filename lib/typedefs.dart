import 'package:flutter/material.dart';

typedef DateTileBuilder = Widget Function(
  DateTime date,
  bool isSelected,
  bool isDeactivated,
);
