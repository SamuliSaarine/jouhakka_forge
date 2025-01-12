import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';

class UIPage extends ElementRoot {
  Color backgroundColor;

  UIPage(
      {required super.title,
      this.backgroundColor = const Color(0xFFFFFFFF),
      super.body})
      : super(id: IDService.newID('pg'));

  factory UIPage.empty() {
    return UIPage(title: "New Page");
  }

  Widget asWidget() {
    return Container(
      color: backgroundColor,
      child: body?.getContent(),
    );
  }
}

abstract class ElementRoot {
  final String id;
  String title;
  UIElement? body;

  Map<String, dynamic> variables = {};

  void setVariable(String key, dynamic value) {
    variables[key] = value;
  }

  void removeVariable(String key) {
    variables.remove(key);
  }

  ElementRoot({required this.id, required this.title, this.body});
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
