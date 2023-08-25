import 'package:editor_demo/controllers/selected_tool_controller.dart';
import 'package:get/get.dart';

Future<void> init() async {
  Get.lazyPut(() => SelectedToolController());
}
