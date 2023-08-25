import 'package:editor_demo/config/routes.dart';
import 'package:editor_demo/helper/di_init.dart' as di;
import 'package:editor_demo/image_editor/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

void main() async {
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: ((context, child) {
        final easyLoading = EasyLoading.init();
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            ScreenUtil.init(
              context,
              designSize: const Size(360, 900),
            );
            child = easyLoading(context, child);
            // Util.setEasyLoading();=======================================================
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child,
            );
          },
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
                // primary: AppColors.textPrimary,
                // secondary: AppColors.primaryMain,
                ),
            // fontFamily: kJost,
          ),
          getPages: Routes.routes,
          initialRoute: routeHome,
          defaultTransition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        );
      }),
    );
  }
}
