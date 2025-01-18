import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';

class UIComponent extends ElementRoot {
  UIComponent({
    required super.title,
    UIElement? body,
  }) : super(id: IDService.newID('c')) {
    super.body = body ?? UIElement.defaultBox(this, parent: null);
  }

  factory UIComponent.empty() {
    final component = UIComponent(title: "New Component");
    return component;
  }
}
