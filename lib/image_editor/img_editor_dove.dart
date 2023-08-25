// import 'dart:io';

// import 'package:editor_demo/image_editor/image_editing_files/flutter_image_editor.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ImageDoveScreen extends StatefulWidget {
//   final String path;
//   final String name;

//   const ImageDoveScreen({super.key, required this.path, required this.name});
//   @override
//   _ImageDoveScreenState createState() => _ImageDoveScreenState();
// }

// class _ImageDoveScreenState extends State<ImageDoveScreen> {
//   File? _image;

//   final picker = ImagePicker();

//   Future<void> toImageEditor(File origin) async {
//     return Navigator.push(context, MaterialPageRoute(builder: (context) {
//       return ImageEditor(
//         name: widget.name,
//         originImage: File(widget.path),
//       );
//     })).then((result) {
//       if (result is EditorImageResult) {
//         setState(() {
//           _image = result.newFile;
//         });
//       }
//     }).catchError((er) {
//       debugPrint(er);
//     });
//   }

//   void getImage() async {
//     // PickedFile? image = await picker.getImage(source: ImageSource.gallery);
//     // if (image != null) {
//     //   final File origin = File(image.path);
//     toImageEditor(File(widget.path));
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (_image != null) Expanded(child: Image.file(_image!)),
//             ElevatedButton(
//               onPressed: getImage,
//               child: Text(
//                 'edit image',
//                 style: TextStyle(
//                   color: Colors.orange,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Widget condition(
//     {required bool condtion, required Widget isTrue, required Widget isFalse}) {
//   return condtion ? isTrue : isFalse;
// }
