import 'dart:ui';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:test/test.dart';

void main() {
  group('VariableParser Tests', () {
    group('String parser tests', () {
      test('Simple string constant', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<String> result = VariableParser.parse<String>(
            '"Hello World"', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<String>>());
        expect((result as ConstantVariable<String>).value, "Hello World");
      });

      test(
        'String concatenation with constants',
        () {
          ElementRoot root = UIPage.empty();
          UIElement element = BranchElement(root: root, parent: null);

          Variable<String> result = VariableParser.parse<String>(
              '"Hello" + " " + "World"', element,
              notifyListeners: () {});
          expect(result, isA<ConstantVariable<String>>());
          expect((result as ConstantVariable<String>).value, "Hello World");
        },
      );

      test(
        'String concatenation with global variable',
        () {
          Project project = Project.empty();
          project.variables
              .setVariable("globalString", ConstantVariable("World"));
          Session.currentProject.value = project;
          ElementRoot root = UIPage.empty();
          UIElement element = BranchElement(root: root, parent: null);

          Variable<String> result = VariableParser.parse<String>(
              '"Hello" + \$globalString', element,
              notifyListeners: () {});
          expect(result, isA<StringFromVariables>());
          var stringFromVariables = result as StringFromVariables;
          expect(stringFromVariables.variables.length, 2);
          expect(
              (stringFromVariables.variables[0] as ConstantVariable<String>)
                  .value,
              "Hello");
          expect(
              (stringFromVariables.variables[1] as GlobalVariable<String>).key,
              "globalString");
        },
      );

      test(
        'String concatenation with root variable',
        () {
          ElementRoot root = UIPage.empty();
          root.variables.setVariable("name", ConstantVariable("World"));
          UIElement element = BranchElement(root: root, parent: null);
          var result = VariableParser.parse<String>(
              '"Hello" + \$root.name', element,
              notifyListeners: () {});
          expect(result, isA<StringFromVariables>());
          var stringFromVariables = result as StringFromVariables;
          expect(stringFromVariables.variables.length, 2);
          expect(
              (stringFromVariables.variables[0] as ConstantVariable<String>)
                  .value,
              "Hello");
          expect((stringFromVariables.variables[1] as RootVariable<String>).key,
              "name");
        },
      );

      test(
        'Complex concatenation with multiple variables',
        () {
          Project project = Project.empty();
          project.variables
              .setVariable("globalString", ConstantVariable("World"));
          Session.currentProject.value = project;
          ElementRoot root = UIPage.empty();
          root.variables.setVariable("name", ConstantVariable("Page"));
          UIElement element = BranchElement(root: root, parent: null);
          var result = VariableParser.parse<String>(
              '"Hello" + \$globalString + " " + \$root.name', element,
              notifyListeners: () {});
          expect(result, isA<StringFromVariables>());
          var stringFromVariables = result as StringFromVariables;
          expect(stringFromVariables.variables.length, 4);
          expect(
              (stringFromVariables.variables[0] as ConstantVariable<String>)
                  .value,
              "Hello");
          expect(
              (stringFromVariables.variables[1] as GlobalVariable<String>).key,
              "globalString");
          expect(
              (stringFromVariables.variables[2] as ConstantVariable<String>)
                  .value,
              " ");
          expect((stringFromVariables.variables[3] as RootVariable<String>).key,
              "name");
        },
      );

      test('Invalid format throws exception', () {
        Project project = Project.empty();
        project.variables
            .setVariable("globalString", ConstantVariable("World"));
        Session.currentProject.value = project;
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);
        expect(
            () => VariableParser.parse<String>(
                '"Hello" + \$globalString + 123', element,
                notifyListeners: () {}),
            throwsException);
      });

      test('Handling spaces around "+" operator', () {
        Project project = Project.empty();
        project.variables
            .setVariable("globalString", ConstantVariable("World"));
        Session.currentProject.value = project;
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);
        var result = VariableParser.parse<String>(
            '"Hello"  +  \$globalString  + " "  +  \$root.name', element,
            notifyListeners: () {});
        expect(result, isA<StringFromVariables>());
        var stringFromVariables = result as StringFromVariables;
        expect(stringFromVariables.variables.length, 4);
        expect(
            (stringFromVariables.variables[0] as ConstantVariable<String>)
                .value,
            "Hello");
        expect((stringFromVariables.variables[1] as GlobalVariable<String>).key,
            "globalString");
        expect(
            (stringFromVariables.variables[2] as ConstantVariable<String>)
                .value,
            " ");
        expect((stringFromVariables.variables[3] as RootVariable<String>).key,
            "name");
      });
    });

    group("Num parser tests", () {
      test('Simple number constant', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result =
            VariableParser.parse<num>('123', element, notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, 123);
      });

      test('Simple number constant with decimal', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result = VariableParser.parse<num>('123.456', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, 123.456);
      });

      test('Simple number constant with negative sign', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result = VariableParser.parse<num>('-123.456', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, -123.456);
      });

      test('Simple number constant with positive sign', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result = VariableParser.parse<num>('+123.456', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, 123.456);
      });

      test('Simple number constant with exponent', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result = VariableParser.parse<num>('123.456e3', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, 123456);
      });

      test('Simple number constant with negative exponent', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<num> result = VariableParser.parse<num>('123.456e-3', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<num>>());
        expect((result as ConstantVariable<num>).value, 0.123456);
      });
    });

    group("Color parser tests", () {
      test('Simple color constant', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<Color> result = VariableParser.parse<Color>('#FF0000', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<Color>>());
        expect(
            (result as ConstantVariable<Color>).value, const Color(0xFFFF0000));
      });

      test('Simple color constant with alpha', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<Color> result = VariableParser.parse<Color>(
            '#80FF0000', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<Color>>());
        expect(
            (result as ConstantVariable<Color>).value, const Color(0x80FF0000));
      });

      test('Simple color constant with alpha and short format', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);
        Variable<Color> result = VariableParser.parse<Color>('#8F0', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<Color>>());
        expect(
            (result as ConstantVariable<Color>).value, const Color(0xFF88FF00));
      });

      test('Simple color constant with alpha and short format with alpha', () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<Color> result = VariableParser.parse<Color>('#8F00', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<Color>>());
        expect(
            (result as ConstantVariable<Color>).value, const Color(0x88FF0000));
      });

      test('Simple color constant with alpha and short format with alpha 2',
          () {
        ElementRoot root = UIPage.empty();
        UIElement element = BranchElement(root: root, parent: null);

        Variable<Color> result = VariableParser.parse<Color>('#8F8', element,
            notifyListeners: () {});
        expect(result, isA<ConstantVariable<Color>>());
        expect(
            (result as ConstantVariable<Color>).value, const Color(0xFF88FF88));
      });
    });
  });
}
