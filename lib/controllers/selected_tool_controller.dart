import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectedToolController extends GetxController implements GetxService {
  RxString selectedToolName = "Pencil".obs;
  Color selectedColor = Colors.red;
}
