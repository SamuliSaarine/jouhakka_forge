import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/ui_element_component.dart';

part 'page.g.dart';

class UIPage extends ElementRoot {
  /// The background color of the page as a hex value.s
  Color backgroundColor;

  /// [UIPage] is [ElementRoot] that scales to the size of the screen and one can navigate to.
  /// One layer can have only one [UIPage].
  UIPage(
      {required super.title,
      this.backgroundColor = Colors.white,
      required super.folder,
      UIElement? body})
      : super(
          id: IDService.newID('pg'),
        ) {
    _body = body?.clone(root: this) ??
        BranchElement(
          root: this,
          parent: null,
          decoration: ElementDecoration(backgroundColor: backgroundColor),
        )
      ..size.width =
          ControlledSize.constant(Session.currentResolution.value.width)
      ..size.height =
          ControlledSize.constant(Session.currentResolution.value.height);
  }

  @override
  factory UIPage.empty({required ElementRootFolder folder}) {
    return UIPage(title: "New Page", folder: folder);
  }

  Widget asWidget() {
    return ElementWidget(
      element: body,
      globalKey: GlobalKey(),
      canApplyInfinity: false,
    );
  }

  @override
  String type({bool plural = false, bool capital = true}) {
    String type = capital ? "Page" : "page";
    return plural ? "${type}s" : type;
  }
}

/// Base class for models that can be the root of an element tree.
@notifier
abstract class ElementRoot extends ChangeNotifier {
  final String id;
  String title;
  ElementRootFolder folder;
  @notify
  late UIElement _body;

  final VariableMap variables = VariableMap();

  @override
  void notifyListeners() {
    super.notifyListeners();
    _body.notifyListeners();
  }

  ElementRoot(
      {required this.id,
      required this.title,
      required this.folder,
      UIElement? body}) {
    if (body != null) {
      _body = body;
    }
  }

  static T empty<T extends ElementRoot>(
      {required ElementRootFolder<T> folder}) {
    if (T == UIPage) {
      return UIPage.empty(folder: folder) as T;
    } else if (T == UIComponent) {
      return UIComponent.empty(folder: folder) as T;
    }
    throw Exception("Unknown ElementRoot type");
  }

  String type({bool plural = false, bool capital = true});
}

class ElementRootFolder<T extends ElementRoot> {
  String name;
  final List<ElementRootFolder<T>> folders = [];
  final List<T> items = [];
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
    debugPrint("Adding new folder $name | ${T.toString()}");
    folders.add(ElementRootFolder<T>(name, parent: this));
  }

  void moveItemTo(T item) {
    debugPrint("Adding new item $item | ${T.toString()}");
    if (item.folder != this) {
      item.folder.items.remove(item);
      item.folder = this;
    }
    items.add(item);
  }

  void newItem() {
    items.add(ElementRoot.empty(folder: this));
  }

  bool removeItem(T item) {
    return items.remove(item);
  }

  bool removeThis() {
    return parent?.folders.remove(this) ?? false;
  }

  T? get first {
    if (items.isNotEmpty) return items.first;
    for (final folder in folders) {
      final item = folder.first;
      if (item != null) return item;
    }
    return null;
  }

  ElementRootFolder(
    this.name, {
    this.parent,
  }) : isExpanded = true;
}

enum DesignMode { wireframe, design, prototype }
