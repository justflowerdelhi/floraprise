import 'package:flutter/foundation.dart';

enum AppShellTab {
  home,
  orders,
  pos,
  inventory,
  money,
}

class AppShellController extends ChangeNotifier {
  AppShellTab _selectedTab = AppShellTab.home;

  AppShellTab get selectedTab => _selectedTab;
  int get selectedIndex => _selectedTab.index;

  void selectTab(AppShellTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }
}
