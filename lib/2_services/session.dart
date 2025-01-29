import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class Session {
  static final ValueNotifier<Project?> currentProject = ValueNotifier(null);
  static final ValueNotifier<UIPage?> lastPage = ValueNotifier(null);
  static final ValueNotifier<UIComponent?> lastComponent = ValueNotifier(null);

  static final ValueNotifier<UIElement?> selectedElement = ValueNotifier(null);
  static final ValueNotifier<UIElement?> hoveredElement = ValueNotifier(null);
  static final ValueNotifier<MouseCursor> globalCursor =
      ValueNotifier(MouseCursor.defer);
  //static final ValueNotifier<Resolution> totalResolution = ValueNotifier(Resolution.iphone13);
  static bool hoverLocked = false;
  static DateTime? _lastHoverTime;
  static Offset? _lastHoverPosition;

  /*static bool checkHoverCooldown() {
    if (_lastHoverTime == null) {
      _lastHoverTime = DateTime.now();
      return true;
    }
    if (DateTime.now().difference(_lastHoverTime!) >
        const Duration(milliseconds: 200)) {
      _lastHoverTime = DateTime.now();
      return true;
    }
    return false;
  }*/

  static Future allowHover(Offset position) async {
    if (_lastHoverPosition == null || _lastHoverTime == null) {
      _lastHoverPosition = position;
      _lastHoverTime = DateTime.now();
      return;
    }
    if ((_lastHoverPosition! - position).distance > 2 ||
        DateTime.now().difference(_lastHoverTime!) >
            const Duration(seconds: 2)) {
      _lastHoverTime = DateTime.now();
      _lastHoverPosition = position;
      return;
    }
    await Future.delayed(DateTime.now().difference(_lastHoverTime!));
    return false;
  }
}
