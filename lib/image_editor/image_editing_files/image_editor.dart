import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:editor_demo/controllers/selected_tool_controller.dart';
import 'package:editor_demo/image_editor/drawing_board_screen.dart';
import 'package:editor_demo/image_editor/home_screen.dart';
import 'package:editor_demo/image_editor/important_files/flutter_drawing_board.dart';
import 'package:editor_demo/image_editor/important_files/src/helper/ex_value_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:ui' as ui;

import 'extension/num_extension.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'model/float_text_model.dart';
import 'widget/drawing_board.dart';
import 'widget/editor_panel_controller.dart';
import 'widget/float_text_widget.dart';
import 'widget/image_editor_delegate.dart';
import 'widget/text_editor_page.dart';

const CanvasLauncher _defaultLauncher =
    CanvasLauncher(mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);

///The editor's result.
class EditorImageResult {
  ///image width
  final int imgWidth;

  ///image height
  final int imgHeight;

  ///new file after edit
  final File newFile;

  EditorImageResult(this.imgWidth, this.imgHeight, this.newFile);
}

///The launcher provides some initial-values for canvas;
class CanvasLauncher {
  factory CanvasLauncher.auto() {
    return const CanvasLauncher(
        mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);
  }

  const CanvasLauncher(
      {required this.mosaicWidth,
      required this.pStrockWidth,
      required this.pColor});

  ///mosaic pixel's width
  final double mosaicWidth;

  ///painter stroke width.
  final double pStrockWidth;

  ///painter color
  final Color pColor;
}

class ImageEditor extends StatefulWidget {
  final DefaultToolsBuilder? defaultToolsBuilder;
  final DrawingController drawingController;
  final String name;
  ImageEditor({
    Key? key,
    required this.originImage,
    this.savePath,
    this.launcher = _defaultLauncher,
    required this.name,
    this.defaultToolsBuilder,
    required this.drawingController,
  }) : super(key: key);

  ///origin image
  /// * input for edit
  final File originImage;

  ///edited-file's save path.
  /// * if null will save in temporary file.
  final Directory? savePath;

  ///provide some initial value
  final CanvasLauncher launcher;

  ///[uiDelegate] is determine the editor's ui style.
  ///You can extends [ImageEditorDelegate] and custome it by youself.
  static ImageEditorDelegate uiDelegate = DefaultImageEditorDelegate();

  @override
  State<StatefulWidget> createState() {
    return ImageEditorState();
  }
}

class ImageEditorState extends State<ImageEditor>
    with
        SignatureBinding,
        ScreenShotBinding,
        TextCanvasBinding,
        RotateCanvasBinding,
        LittleWidgetBinding,
        WindowUiBinding {
  final EditorPanelController _panelController = EditorPanelController();

  final DrawingController _controller = DrawingController();

  double get headerHeight => windowStatusBarHeight;

  double get bottomBarHeight => 105.h + windowBottomBarHeight;

  ///Edit area height.
  double get canvasHeight => 1.sh - bottomBarHeight - headerHeight;

  ///Operation panel button's horizontal space.
  Widget get controlBtnSpacing => 5.hGap;

  ///Save the edited-image to [widget.savePath] or [getTemporaryDirectory()].
  ///
  String selectedToolName = "Select the Tool";

  // final DrawingController _drawingController = DrawingController();

  Future<void> saveImage() async {
    try {
      _panelController.takeShot.value = true;
      screenshotController.capture(pixelRatio: 10).then((value) async {
        final downloadPath = await getDownloadPath();
        final dateTime = DateTime.now();
        final formattedDateTime =
            "${dateTime.year}-${dateTime.month}-${dateTime.day}_${dateTime.hour}-${dateTime.minute}-${dateTime.second}";

        final file = File('$downloadPath/$formattedDateTime${widget.name}.jpg');

        await file.writeAsBytes(value ?? []);

        log('Image saved at: ${file.path}');
      });
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

  // void saveAndMoveToNext() {
  //   _panelController.takeShot.value = true;
  //   screenshotController.capture(pixelRatio: 1.0).then((value) async {
  //     Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) =>
  //               MyDrawingBoardScreen(name: widget.name, img: value),
  //         ));
  //     // final paths = widget.savePath ?? await getTemporaryDirectory();
  //     // final file =
  //     //     await File('${paths.path}/' + DateTime.now().toString() + '.jpg')
  //     //         .create();
  //     // file.writeAsBytes(value ?? []);
  //     // decodeImg().then((value) {
  //     //   if (value == null) {
  //     //     Navigator.pop(context);
  //     //   } else {
  //     //     Navigator.pop(
  //     //         context, EditorImageResult(value.width, value.height, file));
  //     //   }
  //   }).catchError((e) {
  //     Navigator.pop(context);
  //   });
  //   // });
  // }

  Future<ui.Image?> decodeImg() async {
    return await decodeImageFromList(widget.originImage.readAsBytesSync());
  }

  static ImageEditorState? of(BuildContext context) {
    return context.findAncestorStateOfType<ImageEditorState>();
  }

  @override
  void initState() {
    super.initState();
    initPainter();
  }

  @override
  Widget build(BuildContext context) {
    _panelController.screenSize ??= windowSize;
    return Material(
      color: Colors.amber,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: GetBuilder<SelectedToolController>(
            builder: (controller) => Text(
              controller.selectedToolName.value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: const Color(0xff1B84B4),
          actions: [
            IconButton(
              onPressed: () async {
                await saveImage();
                Get.to(() => const HomeScreen());
              },
              icon: const Icon(
                Icons.check,
                color: Colors.white,
              ),
            )
          ],
        ),
        backgroundColor: Colors.black,
        body: Listener(
          onPointerMove: (v) {
            _panelController.pointerMoving(v);
          },
          child: Screenshot(
            controller: screenshotController,
            child: Container(
              // color: Colors.amber,
              height: 1.sh,
              width: 1.sw,
              child: Stack(
                children: [
                  //appBar
                  // ValueListenableBuilder<bool>(
                  //     valueListenable: _panelController.showAppBar,
                  //     builder: (ctx, value, child) {
                  //       return AnimatedPositioned(
                  //           top: 0,
                  //           left: 0,
                  //           right: 0,
                  //           duration: _panelController.panelDuration,
                  //           child: ValueListenableBuilder<bool>(
                  //               valueListenable: _panelController.takeShot,
                  //               builder: (ctx, value, child) {
                  //                 return Opacity(
                  //                   opacity: value ? 0 : 1,
                  //                   child: AppBar(
                  //                     centerTitle: true,
                  //                     automaticallyImplyLeading: false,
                  //                     title: GetBuilder<SelectedToolController>(
                  //                       builder: (controller) => Text(
                  //                         controller.selectedToolName.value,
                  //                         style: const TextStyle(
                  //                           color: Colors.white,
                  //                           fontWeight: FontWeight.w600,
                  //                         ),
                  //                       ),
                  //                     ),
                  //                     backgroundColor: const Color(0xff1B84B4),
                  //                     actions: [
                  //                       IconButton(
                  //                         onPressed: () async {
                  //                           await saveImage();
                  //                           Get.to(() => const HomeScreen());
                  //                         },
                  //                         icon: const Icon(
                  //                           Icons.check,
                  //                           color: Colors.white,
                  //                         ),
                  //                       )
                  //                     ],
                  //                   ),
                  //                   // child: AppBar(
                  //                   //   iconTheme: IconThemeData(
                  //                   //       color: Colors.orange, size: 16),
                  //                   //   leading: backWidget(),
                  //                   //   backgroundColor: Colors.blue,
                  //                   //   actions: [
                  //                   //     resetWidget(onTap: resetCanvasPlate)
                  //                   //   ],
                  //                   // ),
                  //                 );
                  //               }));
                  //     }),
                  //canvas
                  Positioned.fill(
                      top: 1.sh * 0.0,
                      bottom: bottomBarHeight,
                      // left: 0,
                      // right: 0,
                      // rect: Rect.fromLTWH(
                      //   0,
                      //   headerHeight,
                      //   screenWidth,
                      //   canvasHeight,
                      // ),
                      child: RotatedBox(
                        quarterTurns: rotateValue,
                        child: Container(
                          // color: Colors.redAccent,
                          child: Stack(
                            children: [
                              _buildImage(),
                              _buildBrushCanvas(),
                              //buildTextCanvas(),
                            ],
                          ),
                        ),
                      )),
                  //bottom operation(control) bar
                  ValueListenableBuilder<bool>(
                      valueListenable: _panelController.showBottomBar,
                      builder: (ctx, value, child) {
                        return AnimatedPositioned(
                            bottom: value ? 0 : -bottomBarHeight,
                            duration: _panelController.panelDuration,
                            child: SizedBox(
                              width: screenWidth,
                              child: ValueListenableBuilder<bool>(
                                  valueListenable: _panelController.takeShot,
                                  builder: (ctx, value, child) {
                                    return Opacity(
                                      opacity: value ? 0 : 1,
                                      child: _buildControlBar(),
                                    );
                                  }),
                            ));
                      }),
                  //trash bin
                  // ValueListenableBuilder<bool>(
                  //     valueListenable: _panelController.showTrashCan,
                  //     builder: (ctx, value, child) {
                  //       return AnimatedPositioned(
                  //           bottom: value
                  //               ? _panelController.trashCanPosition.dy
                  //               : -headerHeight,
                  //           left: _panelController.trashCanPosition.dx,
                  //           child: _buildTrashCan(),
                  //           duration: _panelController.panelDuration);
                  //     }),
                  //text canvas
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                        0, headerHeight, screenWidth, screenHeight),
                    child: RotatedBox(
                      quarterTurns: rotateValue,
                      child: buildTextCanvas(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _selectedColor = Colors.blue;
  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Get.find<SelectedToolController>().selectedColor,
              onColorChanged: (Color color) {
                log(color.value.toString());
                // setState(() {
                //   _selectedColor = color;
                // });

                Get.find<SelectedToolController>().selectedColor = color;
                Get.find<SelectedToolController>().update();
              },
              // enableLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlBar() {
    return Container(
      // color: Colors.amber,
      width: screenWidth,
      height: bottomBarHeight + 30,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 08),
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<OperateType>(
              valueListenable: _panelController.operateType,
              builder: (ctx, value, child) {
                return Opacity(
                  opacity: _panelController.show2ndPanel() ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: value == OperateType.brush
                        ? MainAxisAlignment.spaceAround
                        : MainAxisAlignment.end,
                    children: [
                      if (value == OperateType.brush)
                        ..._panelController.brushColor
                            .map<Widget>((e) => CircleColorWidget(
                                  color: e,
                                  valueListenable:
                                      _panelController.colorSelected,
                                  onColorSelected: (color) {
                                    if (pColor.value == color.value) return;
                                    changePainterColor(color);
                                  },
                                ))
                            .toList(),
                      35.hGap,
                      unDoWidget(onPressed: undo),
                      // if (value == OperateType.mosaic) 7.hGap,
                    ],
                  ),
                );
              },
            ),
          ),
          // Expanded(
          //   child: ListView(
          //     scrollDirection: Axis.horizontal,
          //     children: [
          //       _buildButton(OperateType.brush, 'Draw', onPressed: () {
          //         setState(() {
          //           selectedToolName = "Draw";
          //         });
          //         switchPainterMode(DrawStyle.normal);
          //       }),
          //       controlBtnSpacing,
          //       _buildButton(OperateType.text, 'Text', onPressed: () {
          //         setState(() {
          //           selectedToolName = "Text";
          //         });
          //         toTextEditorPage();
          //       }),
          //       controlBtnSpacing,
          //       _buildButton(OperateType.flip, 'Flip', onPressed: () {
          //         setState(() {
          //           selectedToolName = "Flip";
          //         });
          //         flipCanvas();
          //       }),
          //       controlBtnSpacing,
          //       _buildButton(OperateType.rotated, 'Rotate', onPressed: () {
          //         setState(() {
          //           selectedToolName = "Rotate";
          //         });
          //         rotateCanvasPlate();
          //       }),
          //       controlBtnSpacing,
          //       _buildButton(OperateType.mosaic, 'Mosaic', onPressed: () {
          //         setState(() {
          //           selectedToolName = "Mosaic";
          //         });
          //         switchPainterMode(DrawStyle.mosaic);
          //       }),
          //       // Expanded(child: SizedBox()),
          //       // const Spacer(),
          //       doneButtonWidget(onPressed: saveAndMoveToNext),
          //       // doneButtonWidget(onPressed: saveImage),

          //       // ...(widget.defaultToolsBuilder?.call(currType, _controller) ??
          //       //         DrawingBoard.defaultTools(currType, _controller))
          //       //     .map((DefToolItem item) => _DefToolItemWidget(item: item))
          //       //     .toList(),
          //     ],
          //   ),
          // ),
          Expanded(
            child: ExValueBuilder<DrawConfig>(
              valueListenable: _controller.drawConfig,
              shouldRebuild: (DrawConfig p, DrawConfig n) =>
                  p.contentType != n.contentType,
              builder: (_, DrawConfig dc, ___) {
                final Type currType = dc.contentType;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildButton(OperateType.setting, 'Settings',
                        onPressed: () {
                      Get.find<SelectedToolController>()
                          .selectedToolName
                          .value = "Settings";

                      Get.find<SelectedToolController>().update();
                      _openColorPicker();
                      // setState(() {
                      //   selectedToolName = "Draw";
                      // });
                      // switchPainterMode(DrawStyle.normal);
                    }),
                    ...(widget.defaultToolsBuilder
                                ?.call(currType, _controller) ??
                            DrawingBoard.defaultTools(currType, _controller))
                        .map(
                            (DefToolItem item) => DefToolItemWidget(item: item))
                        .toList(),

                    _buildButton(OperateType.brush, 'Draw', onPressed: () {
                      Get.find<SelectedToolController>()
                          .selectedToolName
                          .value = "Draw";

                      Get.find<SelectedToolController>().update();
                      // setState(() {
                      //   selectedToolName = "Draw";
                      // });
                      switchPainterMode(DrawStyle.normal);
                    }),
                    controlBtnSpacing,
                    _buildButton(OperateType.text, 'Text', onPressed: () {
                      // setState(() {
                      //   selectedToolName = "Text";
                      // });
                      Get.find<SelectedToolController>()
                          .selectedToolName
                          .value = "Text";

                      Get.find<SelectedToolController>().update();
                      toTextEditorPage();
                    }),
                    controlBtnSpacing,
                    _buildButton(OperateType.flip, 'Flip', onPressed: () {
                      // setState(() {
                      //   selectedToolName = "Flip";
                      // });
                      Get.find<SelectedToolController>()
                          .selectedToolName
                          .value = "Flip";

                      Get.find<SelectedToolController>().update();
                      flipCanvas();
                    }),
                    controlBtnSpacing,
                    _buildButton(OperateType.rotated, 'Rotate', onPressed: () {
                      // setState(() {
                      //   selectedToolName = "Rotate";
                      // });
                      Get.find<SelectedToolController>()
                          .selectedToolName
                          .value = "Rotate";
                      Get.find<SelectedToolController>().update();
                      rotateCanvasPlate();
                    }),
                    controlBtnSpacing,
                    // _buildButton(OperateType.mosaic, 'Mosaic', onPressed: () {
                    //   // setState(() {
                    //   //   selectedToolName = "Mosaic";
                    //   // });
                    //   Get.find<SelectedToolController>()
                    //       .selectedToolName
                    //       .value = "Mosaic";

                    //   Get.find<SelectedToolController>().update();
                    //   switchPainterMode(DrawStyle.mosaic);
                    // }),
                    // Expanded(child: SizedBox()),
                    // const Spacer(),
                    // doneButtonWidget(
                    //   onPressed: () async {
                    //     await saveImage();
                    //   },
                    // ),
                    // doneButtonWidget(onPressed: saveImage),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return DrawingBoard(
      controller: widget.drawingController,
      background: Container(
        // color: Colors.green,
        width: 1.sw,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(flipValue),
          child: Image.file(
            widget.originImage,
            height: 1.sh * 0.77,
          ),
        ),
      ),
    );
  }

  Widget _buildTrashCan() {
    return ValueListenableBuilder<Color>(
        valueListenable: _panelController.trashColor,
        builder: (ctx, value, child) {
          final bool isActive =
              value.value == EditorPanelController.defaultTrashColor.value;
          return Container(
            width: _panelController.tcSize.width,
            height: _panelController.tcSize.height,
            decoration: BoxDecoration(
                color: value,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Column(
              children: [
                12.vGap,
                Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Colors.white,
                ),
                4.vGap,
                Text(
                  isActive ? 'move here for delete' : 'release to delete',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                )
              ],
            ),
          );
        });
  }

  Widget _buildButton(OperateType type, String txt, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: () {
        _panelController.switchOperateType(type);
        onPressed?.call();
      },
      child: ValueListenableBuilder(
        valueListenable: _panelController.operateType,
        builder: (ctx, value, child) {
          return Container(
            // color: Colors.green,
            width: 74,
            // width: 44,
            height: 71,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getOperateTypeRes(type,
                    choosen: _panelController.isCurrentOperateType(type)),
                Text(
                  txt,
                  style: const TextStyle(
                    color: Color(0xFFffffff),
                    // color: _panelController.isCurrentOperateType(type)
                    //     ? const Color(0xFF1B84B4)
                    //     : const Color(0xFFffffff),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

///Little widget binding is for unified manage the widgets that has common style.
/// * If you wanna custom this part, see [ImageEditorDelegate]
mixin LittleWidgetBinding<T extends StatefulWidget> on State<T> {
  ///go back widget
  Widget backWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed ??
          () {
            Navigator.pop(context);
          },
      child: ImageEditor.uiDelegate.buildBackWidget(),
    );
  }

  ///operation button in control bar
  Widget getOperateTypeRes(OperateType type, {required bool choosen}) {
    return ImageEditor.uiDelegate.buildOperateWidget(type, choosen: choosen);
  }

  ///action done widget
  Widget doneButtonWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ImageEditor.uiDelegate.buildDoneWidget(),
    );
  }

  ///undo action
  Widget unDoWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ImageEditor.uiDelegate.buildUndoWidget(),
    );
  }

  ///Ignore pointer evenet by [OperateType]
  Widget ignoreWidgetByType(OperateType type, Widget child) {
    return ValueListenableBuilder(
        valueListenable: realState?._panelController.operateType ??
            ValueNotifier(OperateType.non),
        builder: (ctx, type, c) {
          return IgnorePointer(
            ignoring:
                type != OperateType.brush, //&& type != OperateType.mosaic,
            child: child,
          );
        });
  }

  ///reset button
  Widget resetWidget({VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: 6, right: 16),
      child: ValueListenableBuilder<OperateType>(
        valueListenable: realState?._panelController.operateType ??
            ValueNotifier(OperateType.non),
        builder: (ctx, value, child) {
          return Offstage(
            offstage: value != OperateType.rotated,
            child: GestureDetector(
              onTap: onTap,
              child: ImageEditor.uiDelegate.resetWidget,
            ),
          );
        },
      ),
    );
  }
}

///This binding can make editor to roatate canvas
/// * for now, the paint-path,will change his relative position of canvas
/// * when canvas rotated. because the paint-path area it's full canvas and
/// * origin image is not maybe. if force to keep the relative path, will reduce
/// * the paint-path area.
mixin RotateCanvasBinding<T extends StatefulWidget> on State<T> {
  ///canvas rotate value
  /// * 90 angle each time.
  int rotateValue = 0;

  ///canvas flip value
  /// * 180 angle each time.
  double flipValue = 0;

  ///flip canvas
  void flipCanvas() {
    flipValue = flipValue == 0 ? math.pi : 0;
    setState(() {});
  }

  ///routate canvas
  /// * will effect image, text, drawing board
  void rotateCanvasPlate() {
    rotateValue++;
    setState(() {});
  }

  ///reset canvas
  void resetCanvasPlate() {
    rotateValue = 0;
    setState(() {});
  }
}

///text painting
mixin TextCanvasBinding<T extends StatefulWidget> on State<T> {
  late StateSetter textSetter;

  final List<FloatTextModel> textModels = [];

  void addText(FloatTextModel model) {
    textModels.add(model);
    refreshTextCanvas();
  }

  ///delete a text from canvas
  void deleteTextWidget(FloatTextModel target) {
    textModels.remove(target);
    refreshTextCanvas();
  }

  void toTextEditorPage() {
    realState?._panelController.hidePanel();
    Navigator.of(context)
        .push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return TextEditorPage();
            }))
        .then((value) {
      realState?._panelController.showPanel();
      if (value is FloatTextModel) {
        addText(value);
      }
    });
  }

  void refreshTextCanvas() {
    textSetter.call(() {});
  }

  Widget buildTextCanvas() {
    return StatefulBuilder(builder: (tCtx, setter) {
      textSetter = setter;
      return Stack(
        alignment: Alignment.center,
        children: textModels
            .map<Widget>((e) => Positioned(
                  child: _wrapWithGesture(
                      FloatTextWidget(
                        textModel: e,
                      ),
                      e),
                  left: e.left,
                  top: e.top,
                ))
            .toList(),
      );
    });
  }

  Widget _wrapWithGesture(Widget child, FloatTextModel model) {
    void pointerDetach(DragEndDetails? details) {
      if (details != null) {
        //touch event up
        realState?._panelController.releaseText(details, model, () {
          deleteTextWidget(model);
        });
      } else {
        //touch event cancel
        realState?._panelController.doIdle();
      }
      model.isSelected = false;
      refreshTextCanvas();
      realState?._panelController.showPanel();
    }

    return GestureDetector(
      child: child,
      onPanStart: (_) {
        realState?._panelController.moveText(model);
      },
      onPanUpdate: (details) {
        model.isSelected = true;
        model.left += details.delta.dx;
        model.top += details.delta.dy;
        refreshTextCanvas();
        realState?._panelController.hidePanel();
      },
      onPanEnd: (d) {
        pointerDetach(d);
      },
      onPanCancel: () {
        pointerDetach(null);
      },
    );
  }
}

///drawing board
mixin SignatureBinding<T extends StatefulWidget> on State<ImageEditor> {
  DrawStyle get lastDrawStyle => painterController.drawStyle;

  ///Canvas layer for each draw action action.
  /// * e.g. First draw some path with white color, than change the color and draw some path again.
  /// * After this [pathRecord] will save 2 layes in it.
  final List<Widget> pathRecord = [];

  late StateSetter canvasSetter;

  ///mosaic pixel's width
  double mosaicWidth = 5.0;

  ///painter stroke width.
  double pStrockWidth = 5;

  ///painter color
  Color pColor = Colors.redAccent;

  ///painter controller
  late SignatureController painterController;

  @override
  void initState() {
    super.initState();
    pColor = widget.launcher.pColor;
    mosaicWidth = widget.launcher.mosaicWidth;
    pStrockWidth = widget.launcher.pStrockWidth;
  }

  ///switch painter's style
  /// * e.g. color、mosaic
  void switchPainterMode(DrawStyle style) {
    if (lastDrawStyle == style) return;
    changePainterColor(pColor);
    painterController.drawStyle = style;
  }

  ///change painter's color
  void changePainterColor(Color color) async {
    pColor = color;
    realState?._panelController.selectColor(color);
    pathRecord.insert(
        0,
        RepaintBoundary(
          child: CustomPaint(
              painter: SignaturePainter(painterController),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: double.infinity,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                ),
              )),
        ));
    //savePath();
    initPainter();
    _refreshBrushCanvas();
  }

  void _refreshBrushCanvas() {
    pathRecord.removeLast();
    //add new layer.
    pathRecord.add(Signature(
      controller: painterController,
      backgroundColor: Colors.transparent,
    ));
    _refreshCanvas();
  }

  ///undo last drawing.
  void undo() {
    painterController.undo();
  }

  ///refresh canvas.
  void _refreshCanvas() {
    canvasSetter(() {});
  }

  void initPainter() {
    painterController = SignatureController(
        penStrokeWidth: pStrockWidth,
        penColor: pColor,
        mosaicWidth: mosaicWidth);
  }

  Widget _buildBrushCanvas() {
    if (pathRecord.isEmpty) {
      pathRecord.add(Signature(
        controller: painterController,
        backgroundColor: Colors.transparent,
      ));
    }
    return StatefulBuilder(builder: (ctx, canvasSetter) {
      this.canvasSetter = canvasSetter;
      return realState?.ignoreWidgetByType(
              OperateType.brush,
              Stack(
                children: pathRecord,
              )) ??
          SizedBox();
    });
  }

  @override
  void dispose() {
    pathRecord.clear();
    super.dispose();
  }
}

mixin ScreenShotBinding<T extends StatefulWidget> on State<T> {
  final ScreenshotController screenshotController = ScreenshotController();
}

///information about window
mixin WindowUiBinding<T extends StatefulWidget> on State<T> {
  Size get windowSize => MediaQuery.of(context).size;

  double get windowStatusBarHeight => ui.window.padding.top;

  double get windowBottomBarHeight => ui.window.padding.bottom;

  double get screenWidth => windowSize.width;

  double get screenHeight => windowSize.height;
}

extension _BaseImageEditorState on State {
  ImageEditorState? get realState {
    if (this is ImageEditorState) {
      return this as ImageEditorState;
    }
    return null;
  }
}

///the color selected.
typedef OnColorSelected = void Function(Color color);

class CircleColorWidget extends StatefulWidget {
  final Color color;

  final ValueNotifier<int> valueListenable;

  final OnColorSelected onColorSelected;

  const CircleColorWidget(
      {Key? key,
      required this.color,
      required this.valueListenable,
      required this.onColorSelected})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CircleColorWidgetState();
  }
}

class CircleColorWidgetState extends State<CircleColorWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onColorSelected(widget.color);
      },
      child: ValueListenableBuilder<int>(
        valueListenable: widget.valueListenable,
        builder: (ctx, value, child) {
          final double size = value == widget.color.value ? 25 : 21;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white,
                  width: value == widget.color.value ? 4 : 2),
              shape: BoxShape.circle,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}
