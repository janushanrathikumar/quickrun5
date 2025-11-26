import 'package:flutter/material.dart';
import 'package:quickrun5/common/color_extension.dart';
import 'package:quickrun5/common_widget/tab_button.dart';

import 'package:quickrun5/view/user/home_screen.dart';
import 'package:quickrun5/view/user/order.dart';
import 'package:quickrun5/view/user/user_location_view.dart';
import 'package:quickrun5/view/user/report.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selctTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = const HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            if (selctTab != 2) {
              selctTab = 2;
              selectPageView = const HomeScreen();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: const CircleBorder(),
          backgroundColor: selctTab == 2 ? TColor.primary : TColor.placeholder,
          child: Image.asset("assets/img/tab_home.png", width: 30, height: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: TColor.white,
        shadowColor: Colors.black,
        elevation: 1,
        notchMargin: 12,
        height: 64,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                title: "view location",
                icon: "assets/img/tab_order.png",
                onTap: () {
                  if (selctTab != 1) {
                    selctTab = 1;
                    selectPageView = ActiveDriversMapScreen();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                isSelected: selctTab == 1,
              ),
              const SizedBox(width: 100, height: 100),
              TabButton(
                title: "report",
                icon: "assets/img/tab_more.png",
                onTap: () {
                  if (selctTab != 4) {
                    selctTab = 4;
                    selectPageView = WorkingTimeView();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                isSelected: selctTab == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
