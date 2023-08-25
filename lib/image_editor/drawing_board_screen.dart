import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:editor_demo/controllers/selected_tool_controller.dart';
import 'package:editor_demo/image_editor/home_screen.dart';
import 'package:editor_demo/image_editor/important_files/src/drawing_board.dart';
import 'package:editor_demo/image_editor/important_files/src/drawing_controller.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_contents/eraser.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_contents/paint_content.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_contents/simple_line.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_contents/straight_line.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_extension/ex_offset.dart';
import 'package:editor_demo/image_editor/important_files/src/paint_extension/ex_paint.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'test_data.dart';

const Map<String, dynamic> _testLine1 = <String, dynamic>{
  'type': 'StraightLine',
  'startPoint': <String, dynamic>{
    'dx': 68.94337550070736,
    'dy': 62.05980083656557
  },
  'endPoint': <String, dynamic>{
    'dx': 277.1373386828114,
    'dy': 277.32029957032194
  },
  'paint': <String, dynamic>{
    'blendMode': 3,
    'color': 4294198070,
    'filterQuality': 3,
    'invertColors': false,
    'isAntiAlias': false,
    'strokeCap': 1,
    'strokeJoin': 1,
    'strokeWidth': 4.0,
    'style': 1
  }
};

const Map<String, dynamic> _testLine2 = <String, dynamic>{
  'type': 'StraightLine',
  'startPoint': <String, dynamic>{
    'dx': 106.35164817830423,
    'dy': 255.9575653134524
  },
  'endPoint': <String, dynamic>{
    'dx': 292.76034659254094,
    'dy': 92.125586665872
  },
  'paint': <String, dynamic>{
    'blendMode': 3,
    'color': 4294198070,
    'filterQuality': 3,
    'invertColors': false,
    'isAntiAlias': false,
    'strokeCap': 1,
    'strokeJoin': 1,
    'strokeWidth': 4.0,
    'style': 1
  }
};

class Triangle extends PaintContent {
  Triangle();

  Triangle.data({
    required this.startPoint,
    required this.A,
    required this.B,
    required this.C,
    required Paint paint,
  }) : super.paint(paint);

  factory Triangle.fromJson(Map<String, dynamic> data) {
    return Triangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      A: jsonToOffset(data['A'] as Map<String, dynamic>),
      B: jsonToOffset(data['B'] as Map<String, dynamic>),
      C: jsonToOffset(data['C'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;

  Offset A = Offset.zero;
  Offset B = Offset.zero;
  Offset C = Offset.zero;

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    A = Offset(
        startPoint.dx + (nowPoint.dx - startPoint.dx) / 2, startPoint.dy);
    B = Offset(startPoint.dx, nowPoint.dy);
    C = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  Triangle copy() => Triangle();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'A': A.toJson(),
      'B': B.toJson(),
      'C': C.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class MyDrawingBoardScreen extends StatefulWidget {
  final String? path;
  final String name;
  final Uint8List? img;
  const MyDrawingBoardScreen(
      {Key? key, this.path, required this.name, this.img})
      : super(key: key);

  @override
  State<MyDrawingBoardScreen> createState() => _MyDrawingBoardScreenState();
}

class _MyDrawingBoardScreenState extends State<MyDrawingBoardScreen> {
  final DrawingController _drawingController = DrawingController();

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  Future<void> saveImage(Uint8List imageBytes, String fileName) async {
    try {
      final downloadPath = await getDownloadPath();
      final dateTime = DateTime.now();
      final formattedDateTime =
          "${dateTime.year}-${dateTime.month}-${dateTime.day}_${dateTime.hour}-${dateTime.minute}-${dateTime.second}";

      final file = File('$downloadPath/$formattedDateTime$fileName');

      await file.writeAsBytes(imageBytes);

      log('Image saved at: ${file.path}');
    } catch (e) {
      log('Error saving image: $e');
    }
  }

  Future getDownloadPath() async {
    Directory? directory;
    final req = await Permission.manageExternalStorage.status;
    if (req.isGranted) {
      try {
        if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = Directory('/storage/emulated/0/Download');
          log(directory.path.toString());
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } catch (err) {
        print("Cannot get download folder path");
      }
    } else {
      final newReq = await Permission.manageExternalStorage.request();
      if (newReq.isGranted) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        await Permission.manageExternalStorage.request();
      }
    }

    return directory!.path;
  }

  Future<void> _getImageData() async {
    // _drawingController.setBoardSize(Size(double.infinity, double.infinity));
    final Uint8List? data =
        (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {
      debugPrint('获取图片数据失败');
      return;
    }

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (BuildContext c) {
          return Material(
            color: Colors.white,
            child: Scaffold(
              body: InkWell(
                child: Image.memory(
                  data,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
                onTap: () async {
                  await saveImage(data, widget.name);
                  // Navigator.pop(c);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                  // log("reached here");
                },
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _getJson() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return Center(
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 800),
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ')
                      .convert(_drawingController.getJsonList()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addTestLine() {
    _drawingController.addContent(StraightLine.fromJson(_testLine1));
    _drawingController
        .addContents(<PaintContent>[StraightLine.fromJson(_testLine2)]);
    _drawingController.addContent(SimpleLine.fromJson(tData[0]));
    _drawingController.addContent(Eraser.fromJson(tData[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.orange,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "selectedToolName",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff1B84B4),
        actions: [
          IconButton(
            onPressed: () async {
              await _getImageData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Saved Successfully"),
                ),
              );
            },
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
          )
        ],
      ),
      // appBar: AppBar(
      //   title: const Text('Developed By Greelogix'),
      //   systemOverlayStyle: SystemUiOverlayStyle.light,
      //   actions: <Widget>[
      //     // IconButton(
      //     //     icon: const Icon(Icons.line_axis), onPressed: _addTestLine),
      //     // IconButton(
      //     //     icon: const Icon(Icons.javascript_outlined), onPressed: _getJson),
      //     IconButton(
      //         icon: const Icon(Icons.check),
      //         onPressed: () async {
      //           await _getImageData();
      //           ScaffoldMessenger.of(context).showSnackBar(
      //             const SnackBar(
      //               content: Text("Saved Successfully"),
      //             ),
      //           );
      //         }),
      //     const SizedBox(width: 40),
      //   ],
      // ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return DrawingBoard(
                  // boardPanEnabled: false,
                  // boardScaleEnabled: false,
                  controller: _drawingController,
                  background: Container(
                    // width: constraints.maxWidth,
                    // height: constraints.maxHeight,
                    // color: Colors.white,
                    decoration: const BoxDecoration(
                        // color: Colors.blue,
                        ),
                    child: Image.memory(
                      widget.img!,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.7,
                      width: MediaQuery.of(context).size.width * 1,
                    ),
                    // child: Image.file(
                    //   File(widget.path!),
                    //   fit: BoxFit.contain,
                    //   height: MediaQuery.of(context).size.height * 0.6,
                    //   width: MediaQuery.of(context).size.width * 1,
                    // ),
                  ),
                  showDefaultActions: true,
                  showDefaultTools: true,

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
                );
              },
            ),
          ),
          // Container(
          //   alignment: Alignment.center,
          //   width: double.infinity,
          //   height: 35,
          //   color: Colors.white,
          //   child: const Padding(
          //     padding: EdgeInsets.all(8.0),
          //     child: SelectableText(
          //       'Developed by Greelogix',
          //       style: TextStyle(fontSize: 10, color: Colors.black),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
