import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/2_services/session.dart';

class VariableMap {
  final Map<String, Variable> _variables = {};
  final Map<String, Set<void Function()>> _listeners = {};

  VariableMap();

  List<String> get keys => _variables.keys.toList();
  int get length => _variables.length;

  void setVariable<T>(String key, Variable<T> value) {
    _variables[key] = value;
    _listeners[key]?.forEach((listener) => listener());
  }

  /// Returns the key of the variable
  String setValue<T>(String key, T value, {bool forceNew = false}) {
    if (forceNew && _variables[key] != null) {
      int i = 1;
      while (_variables.containsKey(key)) {
        key = "$key$i";
        i++;
      }
    }
    setVariable(key, ConstantVariable<T>(value));
    return key;
  }

  void removeVariable(String key) {
    _variables.remove(key);
    _listeners.remove(key);
  }

  Variable<T> getVariable<T>(
    String key,
  ) {
    try {
      return _variables[key] as Variable<T>;
    } catch (e) {
      if (_variables[key] == null) {
        throw "Variable $key is null";
      } else if (_variables[key] is! Variable<T>) {
        throw "Variable $key is not of type $T";
      } else {
        rethrow;
      }
    }
  }

  T getValue<T>(String key) {
    try {
      return getVariable<T>(key).value;
    } catch (e) {
      if (T == double && _variables[key]?.typeLabel == "Integer") {
        return getVariable<int>(key).value.toDouble() as T;
      }
      rethrow;
    }
  }

  void addListener(String key, void Function() listener) {
    if (_listeners[key] == null) {
      _listeners[key] = {
        listener,
      };
    } else {
      _listeners[key]!.add(listener);
    }
  }

  void removeListener(String key, void Function() listener) {
    _listeners[key]?.remove(listener);
  }
}

abstract class Variable<T> {
  T get value;

  String get typeLabel {
    if (T == String) {
      return "String";
    } else if (T == double) {
      return "Number";
    } else if (T == int) {
      return "Integer";
    } else if (T == Color) {
      return "Color";
    }
    return "Unknown";
  }

  const Variable();

  Variable<T> clone({void Function()? notifyListeners}) => this;
}

class ConstantVariable<T> extends Variable<T> {
  @override
  final T value;

  @override
  toString() {
    if (value is Color) {
      return (value as Color).toHex().toUpperCase();
    } else if (value is double && value as double == double.infinity) {
      return "inf";
    }
    return value.toString();
  }

  const ConstantVariable(this.value);

  // TO CODE:
  // if (value is Color) {
  //   return 'Color(${value.toRadixString(16)})';
  // }
  // return value.toString();
}

abstract class ListenableVariable<T> extends Variable<T> {
  final void Function() notifyListeners;

  ListenableVariable(this.notifyListeners);

  void dispose() {}

  // TO CODE: 'key'

  @override
  ListenableVariable<T> clone({void Function()? notifyListeners});
}

abstract class SingleListenableVariable<T> extends ListenableVariable<T> {
  final String key;

  SingleListenableVariable(this.key, super.notifyListeners);

  @override
  String toString() => "\$$key";
}

class RootVariable<T> extends SingleListenableVariable<T> {
  final ElementRoot root;

  RootVariable(this.root, super.key, super.notifyListeners) {
    root.variables.addListener(key, notifyListeners);
  }

  @override
  void dispose() {
    root.removeListener(notifyListeners);
  }

  @override
  toString() => "\$root.$key";

  @override
  T get value => root.variables.getValue<T>(key);

  @override
  RootVariable<T> clone(
      {void Function()? notifyListeners, ElementRoot? root, String? key}) {
    if (notifyListeners == null && root == null && key == null) {
      return this;
    }
    return RootVariable(root ?? this.root, key ?? this.key,
        notifyListeners ?? this.notifyListeners);
  }
}

class GlobalVariable<T> extends SingleListenableVariable<T> {
  GlobalVariable(super.key, super.notifyListeners) {
    Session.currentProject.value!.variables.addListener(key, notifyListeners);
  }

  @override
  T get value => Session.currentProject.value!.variables.getValue<T>(key);

  @override
  GlobalVariable<T> clone({void Function()? notifyListeners, String? key}) {
    if (notifyListeners == null && key == null) {
      return this;
    }
    return GlobalVariable(
        key ?? this.key, notifyListeners ?? this.notifyListeners);
  }
}

class StringFromVariables extends Variable<String> {
  final List<Variable> variables;

  StringFromVariables(this.variables);

  @override
  toString() {
    // var, var -> "var" + $var | get toString from each variable and join with +. If variable is string, add quotes
    return variables.map((e) {
      if (e.value is String) {
        return '"${e.value}"';
      }
      return e.toString();
    }).join(" + ");
  }

  @override
  String get value {
    return variables.map((e) => e.value).join();
  }
}

abstract class CalculationOfVariables<T extends num> extends Variable<T> {
  final Variable<T> a;
  final Variable<T> b;

  String toOperatorString(String operator) {
    String aString = a is CalculationOfVariables ? "($a)" : a.toString();
    String bString = b is CalculationOfVariables ? "($b)" : b.toString();
    return "$aString $operator $bString";
  }

  @override
  CalculationOfVariables(this.a, this.b);
}

class SumOfVariables<T extends num> extends CalculationOfVariables<T> {
  SumOfVariables(super.a, super.b);

  @override
  String toString() {
    return toOperatorString("+");
  }

  @override
  T get value => (a.value + b.value) as T;
}

class DifferenceOfVariables<T extends num> extends CalculationOfVariables<T> {
  DifferenceOfVariables(super.a, super.b);

  @override
  String toString() {
    return toOperatorString("-");
  }

  @override
  T get value => (a.value - b.value) as T;
}

class ProductOfVariables<T extends num> extends CalculationOfVariables<T> {
  ProductOfVariables(super.a, super.b);

  @override
  String toString() {
    return toOperatorString("*");
  }

  @override
  T get value => (a.value * b.value) as T;
}

class QuotientOfVariables<T extends num> extends CalculationOfVariables<T> {
  QuotientOfVariables(super.a, super.b);

  @override
  String toString() {
    return toOperatorString("/");
  }

  @override
  T get value => (a.value / b.value) as T;
}

class OverrideOpacityVariable extends ListenableVariable<Color> {
  final Variable<Color> color;
  final Variable<double> opacity;

  OverrideOpacityVariable(
      Variable<Color> color, Variable<double> opacity, super.notifyListeners)
      : color = color is ListenableVariable
            ? color.clone(notifyListeners: notifyListeners)
            : color,
        opacity = opacity is ListenableVariable
            ? opacity.clone(notifyListeners: notifyListeners)
            : opacity;

  @override
  Color get value {
    return color.value.withValues(alpha: opacity.value);
  }

  @override
  String toString() {
    return color.toString();
  }

  @override
  OverrideOpacityVariable clone(
      {void Function()? notifyListeners,
      Variable<Color>? color,
      Variable<double>? opacity}) {
    if (notifyListeners == null && color == null && opacity == null) {
      return this;
    }
    return OverrideOpacityVariable(
      color ?? this.color,
      opacity ?? this.opacity,
      notifyListeners ?? this.notifyListeners,
    );
  }
}

class VariableParser {
  static Variable<T> parse<T>(String input, ElementRoot? root,
      {required void Function() notifyListeners}) {
    if (T == String) {
      return _parseString(input, root, notifyListeners) as Variable<T>;
    } else if (T == Color) {
      return _parseColor(input, root, notifyListeners) as Variable<T>;
    } else if (T == double) {
      return parseNum<double>(input, root, notifyListeners) as Variable<T>;
    } else if (T == int) {
      return parseNum<int>(input, root, notifyListeners) as Variable<T>;
    }
    throw Exception("Unsupported type: $T");
  }

  static Variable parseWithLabel(String label, String input, ElementRoot? root,
      {required void Function() notifyListeners}) {
    switch (label) {
      case "String":
        return _parseString(input, root, notifyListeners);
      case "Number":
        return parseNum<double>(input, root, notifyListeners);
      case "Integer":
        return parseNum<int>(input, root, notifyListeners);
      case "Color":
        return _parseColor(input, root, notifyListeners);
      default:
        throw Exception("Unsupported type: $label");
    }
  }

  static Variable<Color> _parseColor(
      String input, ElementRoot? root, void Function() notifyListeners) {
    if (input.startsWith('\$')) {
      if (input.startsWith('\$root.')) {
        return RootVariable<Color>(root!, input.substring(6), notifyListeners);
      } else {
        return GlobalVariable<Color>(input.substring(1), notifyListeners);
      }
    } else {
      return ConstantVariable<Color>(ColorExtension.fromHex(input));
    }
  }

  static Variable<T> parseNum<T extends num>(
      String input, ElementRoot? root, void Function() notifyListeners,
      {bool normalizeDouble = false}) {
    try {
      String lowerCaseInput = input.toLowerCase();
      if (T == double &&
          (lowerCaseInput == "inf" || lowerCaseInput == "infinity")) {
        return ConstantVariable<T>(double.infinity as T);
      }

      double num = double.parse(input);

      if (T == int) {
        return ConstantVariable<T>(num.toInt() as T);
      } else {
        return ConstantVariable<T>(num as T);
      }

      //debugPrint("Unsupported type: $T");
    } catch (e) {
      //Ignore
    }

    if (input.contains(" + ")) {
      var parts = input.split(" + ").map((part) => part.trim()).toList();
      if (parts.length != 2) {
        throw Exception("Invalid input format: $input");
      }

      return SumOfVariables<T>(
        parseNum<T>(parts[0], root, notifyListeners),
        parseNum<T>(parts[1], root, notifyListeners),
      );
    } else if (input.contains(" - ")) {
      var parts = input.split(" - ").map((part) => part.trim()).toList();
      if (parts.length != 2) {
        throw Exception("Invalid input format: $input");
      }

      return DifferenceOfVariables<T>(
        parseNum<T>(parts[0], root, notifyListeners),
        parseNum<T>(parts[1], root, notifyListeners),
      );
    } else if (input.contains(" * ")) {
      var parts = input.split(" * ").map((part) => part.trim()).toList();
      if (parts.length != 2) {
        throw Exception("Invalid input format: $input");
      }

      return ProductOfVariables<T>(
        parseNum<T>(parts[0], root, notifyListeners),
        parseNum<T>(parts[1], root, notifyListeners),
      );
    } else if (input.contains(" / ")) {
      var parts = input.split(" / ").map((part) => part.trim()).toList();
      if (parts.length != 2) {
        throw Exception("Invalid input format: $input");
      }

      return QuotientOfVariables(
        parseNum(parts[0], root, notifyListeners),
        parseNum(parts[1], root, notifyListeners),
      );
    } else if (input.startsWith('\$')) {
      if (input.startsWith('\$root.')) {
        String key = input.substring(6);
        if (!root!.variables.keys.contains(key)) {
          throw Exception("Root variable $key not found");
        }
        return RootVariable<T>(root, key, notifyListeners);
      } else {
        String key = input.substring(1);
        if (!Session.currentProject.value!.variables.keys.contains(key)) {
          throw Exception("Global variable $key not found");
        }
        return GlobalVariable<T>(key, notifyListeners);
      }
    } else if (input.endsWith('%')) {
      double parsedValue = double.parse(input.substring(0, input.length - 1));
      return ConstantVariable<T>((parsedValue / 100) as T);
    } else {
      double parsedValue = double.parse(input);
      if (T == int) {
        return ConstantVariable<T>(parsedValue.toInt() as T);
      }
      return ConstantVariable<T>(parsedValue as T);
    }
  }

  static Variable<String> _parseString(
      String input, ElementRoot? root, void Function() notifyListeners) {
    if (!input.contains('"')) return ConstantVariable<String>(input);

    // Trim leading/trailing spaces and split by the '+' symbol
    var parts =
        input.split(RegExp(r'\s*\+\s*')).map((part) => part.trim()).toList();

    List<Variable> variables = [];

    bool isConstant = true;

    // Iterate through each part and determine the correct Variable type
    for (var part in parts) {
      if (part.startsWith('"') && part.endsWith('"')) {
        // Handle constant string (e.g., "something")
        variables.add(ConstantVariable<String>(
            part.substring(1, part.length - 1))); // Remove quotes
      } else if (part.startsWith('\$')) {
        isConstant = false;
        // Handle global variable (e.g., $globalstring)
        if (part.startsWith('\$root.')) {
          // Handle root variable (e.g., $root.somestring)
          variables.add(
            RootVariable<String>(
              root!,
              part.substring(6),
              notifyListeners,
            ),
          ); // Adjust accordingly
        } else {
          // Handle global variable (e.g., $globalstring)
          variables.add(
            GlobalVariable<String>(
              part.substring(1),
              notifyListeners,
            ),
          ); // Remove the '$'
        }
      } else {
        throw Exception("Unsupported input format: $part");
      }
    }

    if (isConstant) {
      // If all parts are constants, return a ConstantVariable
      return ConstantVariable<String>(StringFromVariables(variables).value);
    }

    // Return a StringFromVariables with all the parts
    return StringFromVariables(variables);
  }
}
