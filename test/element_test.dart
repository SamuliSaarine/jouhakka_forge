import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:test/test.dart';

void main() {
  void initializePage() {
    Session.currentProject.value = Project("New Project");
    Session.lastPage.value = Session.currentProject.value!.pages.items.first;
  }

  group('element_tests', () {
    setUp(() {
      initializePage();
    });

    test('init element', () {
      expect(Session.currentProject.value!.pages.items.length, 1);
      expect(Session.lastPage.value!.body, isA<BranchElement>());
      expect(Session.lastPage.value!.body.root, Session.lastPage.value);
      expect(
          (Session.lastPage.value!.body as BranchElement).content.value, null);
    });

    group('container_tests', () {
      late final BranchElement body;
      setUp(() {
        initializePage();
        body = Session.lastPage.value!.body as BranchElement;
        body.addElement(UIElementType.box, null);
      });

      void childRelationsCheck(UIElement child) {
        expect(child.root, Session.lastPage.value);
        expect(child.parent, body.content.value);
      }

      test('add test', () {
        expect(body.content.value, isA<ElementContainer>());
        expect(body.content.value!.element, body);
        expect(body.content.value!.type, isA<SingleChildElementType>());
        expect(body.content.value!.children.length, 1);
        expect(body.content.value!.children.first, isA<BranchElement>());
        BranchElement child =
            body.content.value!.children.first as BranchElement;
        childRelationsCheck(child);
      });

      test('decoration test', () {
        BranchElement child =
            body.content.value!.children.first as BranchElement;
        expect(child.decoration.value, isNotNull);
        ElementDecoration decoration = child.decoration.value!;
        expect(decoration.backgroundColor.value, Colors.white);
        expect(decoration.border.value, isNotNull);
        expect(decoration.border.value!.equalSides, true);
        expect(decoration.border.value!.top.color.value, Colors.black);
        expect(decoration.border.value!.top.width.value, 1);
      });

      test('Column test', () {
        body.addElement(null, AddDirection.bottom);
        ElementContainer container = body.content.value!;
        expect(container.children.length, 2);
        expect(container.type, isA<FlexElementType>());
        expect((container.type as FlexElementType).direction, Axis.vertical);
        expect(container.children.last, isA<BranchElement>());
        BranchElement child = container.children.last as BranchElement;
        childRelationsCheck(child);
        expect(child.decoration.value, isNotNull);
        ElementDecoration decoration = child.decoration.value!;
        expect(
            decoration.equals(
                (container.children.first as BranchElement).decoration.value!),
            true);
      });

      test('Remove test', () {
        body.addElement(null, AddDirection.bottom);
        expect(body.content.value!.children.length, 2);
        ElementContainer container = body.content.value!;
        container.removeChild(container.children.last);
        expect(container.children.length, 1);
        container.removeChild(container.children.first);
        expect(body.content.value, null);
      });

      test('Row test', () {
        body.addElement(null, AddDirection.right);
        expect((body.content.value!.type as FlexElementType).direction,
            Axis.horizontal);
      });
    });
  });
}
