import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';

class UIPage extends ElementRoot {
  /// The background color of the page as a hex value.s
  int backgroundHex;

  /// [UIPage] is [ElementRoot] that scales to the size of the screen and one can navigate to.
  /// One layer can have only one [UIPage].
  UIPage(
      {required super.title, this.backgroundHex = 0xFFFFFFFF, UIElement? body})
      : super(
          id: IDService.newID('pg'),
        ) {
    super.body = body ?? UIElement(root: this, parent: null);
  }

  factory UIPage.empty() {
    return UIPage(title: "New Page");
  }

  Widget asWidget() {
    return ElementWidget(element: body, globalKey: GlobalKey());
  }
}

/// Base class for models that can be the root of an element tree.
abstract class ElementRoot {
  final String id;
  String title;
  late UIElement body;

  Map<String, dynamic> variables = {};

  void setVariable(String key, dynamic value) {
    variables[key] = value;
  }

  void removeVariable(String key) {
    variables.remove(key);
  }

  T getVariable<T>(String key) {
    try {
      return variables[key] as T;
    } catch (e) {
      if (variables[key] == null) {
        throw "Variable $key is null";
      } else if (variables[key] is! T) {
        throw "Variable $key is not of type $T";
      } else {
        rethrow;
      }
    }
  }

  ElementRoot({required this.id, required this.title, UIElement? body}) {
    if (body != null) {
      this.body = body;
    }
  }
}

class ElementRootFolder<T extends ElementRoot> {
  String name;
  final List<ElementRootFolder<T>> folders;
  final List<T> items;
  ElementRootFolder<T>? parent;
  bool isExpanded;

  int get totalItems {
    int sum = items.length;
    for (final folder in folders) {
      sum += folder.totalItems;
    }
    return sum;
  }

  void addNewFolder(String name) {
    folders.add(ElementRootFolder(name, parent: this));
  }

  void addNewItem(T item) {
    items.add(item);
  }

  T? get first {
    if (items.isNotEmpty) return items.first;
    for (final folder in folders) {
      final item = folder.first;
      if (item != null) return item;
    }
    return null;
  }

  ElementRootFolder(this.name,
      {this.parent, this.items = const [], this.folders = const []})
      : isExpanded = true;
}

enum DesignMode { wireframe, design, prototype }
