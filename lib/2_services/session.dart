import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';

class Session {
  // Selections management
  /// The current project that is being edited.
  static final ValueNotifier<Project?> currentProject = ValueNotifier(null);

  /// The element that is currently selected.
  static final ValueNotifier<UIElement?> selectedElement = ValueNotifier(null);
  static final ValueNotifier<Resolution> currentResolution =
      ValueNotifier(Resolution.iphone13);

  //History management
  /// The page that was last edited. If you go to edit settings or components, you dont need to explore page list again to find the page you were editing.
  static final ValueNotifier<UIPage?> lastPage = ValueNotifier(null);
  static final ValueNotifier<UIComponent?> lastComponent = ValueNotifier(null);

  //Interaction management
  static final ValueNotifier<UIElement?> hoveredElement = ValueNotifier(null);
  static Offset? localHoverPosition;
  static final ValueNotifier<MouseCursor> globalCursor =
      ValueNotifier(MouseCursor.defer);
  static bool hoverLocked = false;
  static ValueNotifier<bool> ctrlDown = ValueNotifier(false);
  static ValueNotifier<bool> extraPadding = ValueNotifier(false);
  static double zoom = 1.0;
  static ValueNotifier<AddDirection?> addDirection = ValueNotifier(null);

  static const bool scrollEditor = true;
}
