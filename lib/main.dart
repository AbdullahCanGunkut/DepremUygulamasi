import 'dart:isolate';
import 'package:flutter/material.dart';
import 'kernel.dart';
import 'ui.dart';
import 'dart:async';

void main() async {
  Future(() async{await kernel_init();}).then((value){});
  runApp(const DepremApp());
}

