import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class Session {
  static final ValueNotifier<Project?> currentProject = ValueNotifier(null);
  static final ValueNotifier<ElementRoot?> currentElementRoot =
      ValueNotifier(null);
  static final ValueNotifier<UIElement?> selectedElement = ValueNotifier(null);
  static final ValueNotifier<UIElement?> hoveredElement = ValueNotifier(null);
  static final ValueNotifier<MouseCursor> globalCursor =
      ValueNotifier(MouseCursor.defer);
}
