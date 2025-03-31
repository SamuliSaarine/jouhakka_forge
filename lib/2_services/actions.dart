import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';

class ActionService {
  static Queue<MyAction> appliedActions = Queue<MyAction>();
  static Queue<MyAction> undoneActions = Queue<MyAction>();

  static bool listFromMap(Map<String, dynamic> actionMap) {
    try {
      List<Map<String, dynamic>> actions =
          (actionMap['actions'] as List).cast<Map<String, dynamic>>();
      for (Map<String, dynamic> action in actions) {
        singleFromMap(action);
      }
      return true;
    } catch (e) {
      debugPrint("Error in listFromMap: $e");
      return false;
    }
  }

  static bool singleFromMap(Map<String, dynamic> actionMap, {dynamic output}) {
    try {
      String action = actionMap['action'];
      UIElement? target;
      if (actionMap['target']['format'] == 'output') {
        target = output;
      } else {
        target = MyAction.elementFromPath(
            ((actionMap['target']['path'] ?? []) as List).cast<int>());
      }
      if (target == null) return false;
      switch (action) {
        case 'add':
          if (target is! BranchElement) {
            debugPrint("Target is not a BranchElement");
            return false;
          }
          return addActionFromMap(actionMap, target: target);
        case 'update':
          return updateActionFromMap(actionMap, target: target);
      }
      return false;
    } catch (e) {
      debugPrint("Error in singleFromMap: $e");
      return false;
    }
  }

  static bool actionsFromList(List<Map<String, dynamic>> actionList) {
    try {
      for (Map<String, dynamic> action in actionList) {
        try {
          String actionType = action['action'];
          UIElement? target = MyAction.elementFromPath(
              ((action['target'] ?? []) as List).cast<int>());

          if (target == null) {
            debugPrint("Target element is null");
            return false;
          }
          Map<String, String> args = {};
          List<Map<String, dynamic>> argsList =
              (action['arguments'] as List).cast<Map<String, dynamic>>();
          for (Map<String, dynamic> arg in argsList) {
            args[arg['name']] = arg['value'];
          }
          MyAction? result = target.handleAction(actionType, args);
          if (result != null) {
            appliedActions.add(result);
          }
        } catch (e) {
          debugPrint("Error running action $action: $e");
        }
      }
      return true;
    } catch (e, s) {
      debugPrint("Error in actionsFromList: $e | $s");
      return false;
    }
  }

  static bool addActionFromMap(
    Map<String, dynamic> actionMap, {
    required BranchElement target,
    AddDirection? addDirection,
  }) {
    try {
      return AddElementTypeAction.run(
        UIElementType.fromString(actionMap['element']),
        target,
        addDirection: actionMap['direction'] != null
            ? AddDirection.fromString(actionMap['direction'])
            : null,
        then: (element) {
          if (actionMap['then'] != null) {
            Map<String, dynamic> thenActions =
                actionMap['then'] as Map<String, dynamic>;
            listFromMap(thenActions);
          }
          return true;
        },
      );
    } catch (e) {
      debugPrint("Error in addFromMap: $e");
      return false;
    }
  }

  static bool updateActionFromMap(
    Map<String, dynamic> actionMap, {
    required UIElement target,
  }) {
    try {
      return UpdateAction.run(
        target,
        property: actionMap['property'],
        value: actionMap['value'],
      );
    } catch (e) {
      debugPrint("Error in updateFromMap: $e");
      return false;
    }
  }
}

abstract class MyAction {
  static UIElement? elementFromPath(List<int> path,
      {ElementRoot? root, bool createIfNotPresent = false}) {
    try {
      ElementRoot currentRoot = root ?? Session.lastPage.value!;
      UIElement element = currentRoot.elementFrom(path);
      return element;
    } catch (e) {
      debugPrint("Error parsing path: $e");
      return null;
    }
  }

  void undo();
  void redo();
}

class UpdateAction<T> extends MyAction {
  final T oldValue;
  final T newValue;
  final void Function(T) set;

  UpdateAction({
    required this.oldValue,
    required this.newValue,
    required this.set,
  }) {
    if (oldValue == newValue) {
      debugPrint(
          "Warning: Old value and new value are the same. Skipping action.");
    }
  }

  static bool run(
    UIElement target, {
    required String property,
    required String value,
  }) {
    try {
      UpdateAction? action = target.setValue(property, value);
      if (action == null) return false;
      ActionService.appliedActions.add(action);
      return true;
    } catch (e) {
      debugPrint("Error in UpdateAction.run: $e");
      return false;
    }
  }

  @override
  void undo() {
    try {
      set(oldValue);
      ActionService.undoneActions.add(this);
    } catch (e) {
      debugPrint("Error in UpdateAction.undo: $e");
    }
  }

  @override
  void redo() {
    try {
      set(newValue);
      ActionService.appliedActions.add(this);
    } catch (e) {
      debugPrint("Error in UpdateAction.redo: $e");
    }
  }
}

abstract class ActionWithOutput extends MyAction {
  final dynamic output;
  @override
  ActionWithOutput({required this.output});
}

class AddElementTypeAction extends ActionWithOutput {
  final UIElementType type;
  final BranchElement targetElement;

  AddElementTypeAction._(this.type, this.targetElement,
      {required super.output});

  static bool run(
    UIElementType type,
    BranchElement targetElement, {
    AddDirection? addDirection,
    bool Function(UIElement element)? then,
  }) {
    try {
      UIElement element = targetElement.addChildFromType(type, addDirection);

      ActionService.appliedActions
          .add(AddElementTypeAction._(type, targetElement, output: element));

      if (then != null) {
        try {
          then(element);
        } catch (e) {
          debugPrint("Error in then function: $e");
        }
      }

      debugPrint("Added $type to $targetElement");
      return true;
    } catch (e) {
      debugPrint("Error in AddElementTypeAction.run: $e");
      return false;
    }
  }

  @override
  void undo() {
    try {
      targetElement.content.value!.removeChild(output);
      ActionService.undoneActions.add(this);
    } catch (e) {
      debugPrint("Error in AddElementTypeAction.undo: $e");
    }
  }

  @override
  void redo() {
    try {
      targetElement.addChild(output, null);
      ActionService.appliedActions.add(this);
    } catch (e) {
      debugPrint("Error in AddElementTypeAction.redo: $e");
    }
  }
}

class RemoveElementAction extends MyAction {
  final UIElement element;
  final BranchElement parentElement;

  RemoveElementAction(this.element, this.parentElement);

  static bool run(UIElement element) {
    try {
      BranchElement parent = element.parent as BranchElement;
      parent.content.value!.removeChild(element);
      ActionService.appliedActions.add(RemoveElementAction(element, parent));
      return true;
    } catch (e) {
      debugPrint("Error in RemoveElementAction.run: $e");
      return false;
    }
  }

  @override
  void undo() {
    try {
      parentElement.addChild(element, null);
      ActionService.undoneActions.add(this);
    } catch (e) {
      debugPrint("Error in RemoveElementAction.undo: $e");
    }
  }

  @override
  void redo() {
    try {
      parentElement.content.value!.removeChild(element);
      ActionService.appliedActions.add(this);
    } catch (e) {
      debugPrint("Error in RemoveElementAction.redo: $e");
    }
  }
}
