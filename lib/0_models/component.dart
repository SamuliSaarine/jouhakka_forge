import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';

class UIComponent extends ElementRoot {
  /// [UIComponent] is [ElementRoot] for [UIElement]s that can be reused in multiple [ElementRoot]s or multiple times in the same [ElementRoot].
  ///
  /// That means that when you edit the [UIComponent], all the instances of it will be updated.
  ///
  /// [UIComponent]s are designed to be used as a child of another [UIElement] so even you can edit [UIComponent] individually, it must have instances inside another [ElementRoot]s to be useful.
  UIComponent({
    required super.title,
    UIElement? body,
  }) : super(id: IDService.newID('c')) {
    this.body = body ?? BranchElement.defaultBox(this, parent: null);
  }

  factory UIComponent.empty() {
    final component = UIComponent(title: "New Component");
    return component;
  }

  @override
  String type({bool plural = false, bool capital = true}) {
    String type = capital ? "Component" : "component";
    return plural ? "${type}s" : type;
  }
}
