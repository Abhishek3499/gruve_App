import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Interactions screen controller
class InteractionsController extends Notifier<int> {
  static const List<String> _tabs = ['All', 'Followers', 'Non-followers'];

  @override
  int build() => 0;

  int get selectedTab => state;
  List<String> get tabs => _tabs;

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length && index != state) {
      AppLogger.d("[InteractionsController] Tab changed to: ${_tabs[index]}");
      state = index;
    }
  }

  bool isTabActive(int index) {
    return state == index;
  }
}

final interactionsControllerProvider =
    NotifierProvider<InteractionsController, int>(InteractionsController.new);
