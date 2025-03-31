import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';

void main() {
  group('UIElement Serialization Tests', () {
    setUp(() {
      Session.currentProject.value = Project("New Project");
      Session.lastPage.value = Session.currentProject.value!.pages.items.first;
    });

    test('Serialize UIElement to JSON', () {
      UIElement element =
          BranchElement(root: Session.lastPage.value!, parent: null);
      final json = element.toJson();

      debugPrint(json.toString());
      expect(json, {
        'type': 'branch',
        'id': element.id,
        'width': {'type': 'expand', 'min': '0.0', 'max': 'inf', 'flex': '1'},
        'height': {'type': 'expand', 'min': '0.0', 'max': 'inf', 'flex': '1'},
        'decoration': null,
        'content': null,
      });
    });

    test('Deserialize JSON to UIElement', () {
      final json = {
        'type': 'branch',
        'id': '1',
        'width': {'type': 'expand', 'min': '0.0', 'max': 'inf', 'flex': '1'},
        'height': {'type': 'expand', 'min': '0.0', 'max': 'inf', 'flex': '1'},
        'content': null,
        'decoration': null,
      };
      final uiElement =
          BranchElement.fromJson(json, Session.lastPage.value!, null);
      expect(uiElement.id, '1');
      expect(uiElement.size.width, isA<ExpandingSize>());
      expect(uiElement.size.height, isA<ExpandingSize>());
      expect(uiElement.decoration.value, null);
      expect(uiElement.content.value, null);
    });

    test('Serialize and Deserialize UIElement', () {
      final uiElement = BranchElement(
        root: Session.lastPage.value!,
        parent: null,
      );
      final json = uiElement.toJson();
      final deserializedElement =
          BranchElement.fromJson(json, Session.lastPage.value!, null);
      expect(deserializedElement.id, uiElement.id);
      expect(deserializedElement.size.width.runtimeType,
          uiElement.size.width.runtimeType);
      expect(deserializedElement.size.height.runtimeType,
          uiElement.size.height.runtimeType);
      expect(deserializedElement.decoration.value, uiElement.decoration.value);
      expect(deserializedElement.content.value, uiElement.content.value);
    });

    test('complex test', () {
      final element = BranchElement(
        root: Session.lastPage.value!,
        parent: null,
        decoration: ElementDecoration.defaultBox,
      );
      element.addChildFromType(UIElementType.icon, null);
      element.addChildFromType(UIElementType.box, AddDirection.right);
      (element.content.value!.children.last as BranchElement)
          .addChildFromType(UIElementType.text, null);

      final json = element.toJson();
      final deserializedElement =
          BranchElement.fromJson(json, Session.lastPage.value!, null);
      final json2 = deserializedElement.toJson();
      expect(json, json2);
    });
  });
}
