import 'dart:developer';
import 'dart:io';
import 'package:editor_demo/controllers/selected_tool_controller.dart';
import 'package:editor_demo/image_editor/drawing_board_screen.dart';
import 'package:editor_demo/image_editor/image_editing_files/flutter_image_editor.dart';
import 'package:editor_demo/image_editor/important_files/flutter_drawing_board.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_photo_editor/flutter_photo_editor.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _platformVersion = 'Unknown';
  final _flutterPhotoEditorPlugin = FlutterPhotoEditor();
  final DrawingController _drawingController = DrawingController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _flutterPhotoEditorPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Developed By Greelogix'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: TextButton(
                onPressed: () {
                  test();
                },
                child: const Text("Add photo"),
              ),
            ),
            if (imagePath != null)
              Image.file(
                File(imagePath!),
                width: 300,
                height: 500,
              )
          ],
        ),
      ),
    );
  }

  String? imagePath;

  void test() async {
    print("start");

    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    String? path = image?.path;
    String? name = image?.name;
    // onImageEdit(path);
    if (path != null && name != null) {
      editImage(path: path, name: name);
    }
  }

  void editImage({required String path, required String name}) async {
    print("path: $path");

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ImageDoveScreen(path: path, name: name),
    //   ),

    // MaterialPageRoute(
    //   builder: (context) => MyDrawingBoardScreen(
    //     path: path,
    //     name: name,
    //   ),
    // ),
    // );

    Get.to(
        () => ImageEditor(
              name: name,
              originImage: File(path),
              drawingController: _drawingController,
              defaultToolsBuilder: (Type t, _) {
                return DrawingBoard.defaultTools(t, _drawingController)
                  ..insert(
                    1,
                    DefToolItem(
                      onClick: () {
                        Get.find<SelectedToolController>()
                            .selectedToolName
                            .value = "Triangle";
                        Get.find<SelectedToolController>().update();
                      },
                      icon: Icons.change_history_rounded,
                      isActive: t == Triangle,
                      name: "Triangle",
                      onTap: () =>
                          _drawingController.setPaintContent(Triangle()),
                    ),
                  );
              },
            ), binding: BindingsBuilder(() {
      // Get.put(SelectedToolController());
    }));

    setState(() {
      imagePath = path;
    });
    // print("end : $b");
  }
}
