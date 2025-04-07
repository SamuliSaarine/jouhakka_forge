import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/2_services/actions.dart';
import 'package:jouhakka_forge/5_style/icons/lucide_map.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';

part 'media_elements.g.dart';

abstract class LeafElement extends UIElement {
  LeafElement({
    required super.root,
    super.parent,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'leaf',
      ...super.toJson(),
    };
  }

  LeafElement.fromJson(super.json, super.root, super.parent) : super.fromJson();

  static LeafElement? tryFromJson(
      Map<String, dynamic> json, ElementRoot root, ElementContainer? parent) {
    try {
      switch (json["leaf"]["type"]) {
        case "text":
          return TextElement.fromJson(json, root, parent);
        case "image":
          return ImageElement.fromJson(json, root, parent);
        case "icon":
          return IconElement.fromJson(json, root, parent);
        default:
          throw Exception("Unknown leaf type: ${json["leaf"]["type"]}");
      }
    } catch (e) {
      debugPrint("Error deserializing leaf element: $e");
      return null;
    }
  }
}

@notifier
class TextElement extends LeafElement {
  @notify
  Variable<String> _text = ConstantVariable("");
  @notify
  Variable<Color> _color = ConstantVariable(Colors.black);
  @notify
  Variable<double> _fontSize = ConstantVariable(18);
  @notify
  FontWeight _fontWeight = FontWeight.normal;
  @notify
  Alignment _alignment = Alignment.center;

  /// [TextElement] is a [UIElement] that displays text.
  TextElement(
    Variable<String> text, {
    required super.root,
    super.parent,
  }) : _text = text;

  factory TextElement.from(UIElement element, Variable<String> text) =>
      TextElement(
        text,
        root: element.root,
        parent: element.parent,
      )..copy(element);

  @override
  Widget getContent() {
    return Align(
      alignment: alignment,
      child: Text(
        text.value,
        textAlign: alignment.getTextAlignment(),
        style: TextStyle(
          color: color.value,
          fontSize: fontSize.value,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  @override
  void copy(UIElement other) {
    super.copy(other);
    if (other is TextElement) {
      color = other.color;
      fontSize = other.fontSize;
      fontWeight = other.fontWeight;
      alignment = other.alignment;
    }
  }

  @override
  LeafElement clone({ElementRoot? root, ElementContainer? parent}) =>
      TextElement(
        text,
        root: root ?? this.root,
        parent: parent ?? this.parent,
      )..copy(this);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "leaf": {
        "type": "text",
        "text": text.toString(),
        "color": color.toString(),
        "fontSize": fontSize.toString(),
        "fontWeight": fontWeight.toJson(),
        "alignment": alignment.toJson(),
      }
    };
  }

  TextElement.fromJson(
      Map<String, dynamic> json, ElementRoot root, ElementContainer? parent)
      : super.fromJson(json, root, parent) {
    Map<String, dynamic> leaf = json['leaf'];
    _text = VariableParser.parse<String>(leaf['text'], root,
        notifyListeners: notifyListeners);
    color = VariableParser.parse<Color>(leaf['color'], root,
        notifyListeners: notifyListeners);
    fontSize = VariableParser.parse<double>(leaf['fontSize'], root,
        notifyListeners: notifyListeners);
    fontWeight = FontWeightExtension.fromString(leaf['fontWeight']);
    alignment = AlignmentExtension.fromString(leaf['alignment']);
  }

  @override
  UpdateAction? setValue(String property, String value) {
    switch (property) {
      case "text":
        var newValue = VariableParser.parse<String>(value, root,
            notifyListeners: notifyListeners);
        if (text == newValue) return null;
        var old = text;
        text = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: text,
          set: (v) => text = v,
        );
      case "color":
        var newValue = VariableParser.parse<Color>(value, root,
            notifyListeners: notifyListeners);
        if (color == newValue) return null;
        var old = color;
        color = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: color,
          set: (v) => color = v,
        );
      case "fontSize":
        var newValue = VariableParser.parse<double>(value, root,
            notifyListeners: notifyListeners);
        if (fontSize == newValue) return null;
        var old = fontSize;
        fontSize = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: fontSize,
          set: (v) => fontSize = v,
        );
      case "fontWeight":
        var newValue = FontWeightExtension.fromString(value);
        if (fontWeight == newValue) return null;
        var old = fontWeight;
        fontWeight = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: fontWeight,
          set: (v) => fontWeight = v,
        );
      case "alignment":
        var newValue = AlignmentExtension.fromString(value);
        if (alignment == newValue) return null;
        var old = alignment;
        alignment = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
    }
    return super.setValue(property, value);
  }

  @override
  MyAction? handleAction(String action, Map<String, String> args) {
    switch (action) {
      case "setText":
        var newValue = VariableParser.parse<String>(
            args["text"] ?? text.value, root,
            notifyListeners: notifyListeners);
        if (text == newValue) return null;
        var old = text;
        text = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: text,
          set: (v) => text = v,
        );
      case "setTextStyle":
        if (args["fontSize"] != null) {
          var newValue = VariableParser.parse<double>(
              args["fontSize"] ?? "18", root,
              notifyListeners: notifyListeners);
          if (fontSize == newValue) return null;
          var old = fontSize;
          fontSize = newValue;
          return UpdateAction(
            oldValue: old,
            newValue: fontSize,
            set: (v) => fontSize = v,
          );
        }
        if (args["fontWeight"] != null) {
          var newValue =
              FontWeightExtension.fromString(args["fontWeight"] ?? "medium");
          if (fontWeight == newValue) return null;
          var old = fontWeight;
          fontWeight = newValue;
          return UpdateAction(
            oldValue: old,
            newValue: fontWeight,
            set: (v) => fontWeight = v,
          );
        }
        if (args["color"] != null) {
          var newValue = VariableParser.parse<Color>(
              args["color"] ?? "#000000FF", root,
              notifyListeners: notifyListeners);
          if (color == newValue) return null;
          var old = color;
          color = newValue;
          return UpdateAction(
            oldValue: old,
            newValue: color,
            set: (v) => color = v,
          );
        }
        return null;
    }
    return super.handleAction(action, args);
  }

  @override
  String get label => "Text";
}

enum ImageSource { asset, network }

@notifier
class ImageElement extends LeafElement {
  /// File path or URL of the image.
  @notify
  String _imagePath;

  /// Source of the image. Can be either an asset or a network image.
  @notify
  ImageSource _source = ImageSource.asset;

  /// How the image should be fitted into the box.
  @notify
  BoxFit _fit = BoxFit.cover;

  /// How the image should be aligned within its box.
  @notify
  Alignment _alignment = Alignment.center;

  /// [ImageElement] is a [UIElement] that displays an image.
  ImageElement({
    String imagePath = "images/placeholder.png",
    required super.root,
    super.parent,
  }) : _imagePath = imagePath;

  factory ImageElement.from(UIElement element,
          {String imagePath = "images/placeholder.png"}) =>
      ImageElement(
        imagePath: imagePath,
        root: element.root,
        parent: element.parent,
      )..copy(element);

  @override
  Widget getContent() {
    return Image(
      image: source == ImageSource.asset
          ? AssetImage(imagePath)
          : NetworkImage(imagePath),
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => Image(
        image: AssetImage("images/placeholder.png"),
        fit: fit,
        alignment: alignment,
      ),
    );
  }

  @override
  void copy(UIElement other) {
    super.copy(other);
    if (other is ImageElement) {
      imagePath = other.imagePath;
      source = other.source;
      fit = other.fit;
      alignment = other.alignment;
    }
  }

  @override
  LeafElement clone({ElementRoot? root, ElementContainer? parent}) =>
      ImageElement(
        imagePath: imagePath,
        root: root ?? this.root,
        parent: parent ?? this.parent,
      )..copy(this);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "leaf": {
        "type": "image",
        "imagePath": imagePath,
        "source": source.toString(),
        "fit": fit.toString(),
        "alignment": alignment.toString(),
      }
    };
  }

  ImageElement.fromJson(
      Map<String, dynamic> json, ElementRoot root, ElementContainer? parent)
      : _imagePath = json['leaf']['imagePath'],
        super.fromJson(json, root, parent) {
    Map<String, dynamic> leaf = json['leaf'];
    final sourceString = leaf['source'];
    for (ImageSource source in ImageSource.values) {
      if (source.toString() == sourceString) {
        this.source = source;
        break;
      }
    }
    final fitString = leaf['fit'];
    for (BoxFit fit in BoxFit.values) {
      if (fit.toString() == fitString) {
        this.fit = fit;
        break;
      }
    }
    alignment = AlignmentExtension.fromString(leaf['alignment']);
  }

  @override
  UpdateAction? setValue(String property, String value) {
    switch (property) {
      case "imagePath":
        var old = imagePath;
        imagePath = value;
        return UpdateAction(
          oldValue: old,
          newValue: imagePath,
          set: (v) => imagePath = v,
        );
      case "source":
        var old = source;
        source = ImageSource.values.firstWhere((e) => e.toString() == value,
            orElse: () => ImageSource.asset);
        return UpdateAction(
          oldValue: old,
          newValue: source,
          set: (v) => source = v,
        );
      case "fit":
        var old = fit;
        fit = BoxFit.values.firstWhere((e) => e.toString() == value,
            orElse: () => BoxFit.cover);
        return UpdateAction(
          oldValue: old,
          newValue: fit,
          set: (v) => fit = v,
        );
      case "alignment":
        var old = alignment;
        alignment = AlignmentExtension.fromString(value);
        return UpdateAction(
          oldValue: old,
          newValue: alignment,
          set: (v) => alignment = v,
        );
    }
    return super.setValue(property, value);
  }

  @override
  MyAction? handleAction(String action, Map<String, String> args) {
    switch (action) {
      case "setImageProps":
        if (args["path"] != null) {
          String old = imagePath;
          imagePath = args["path"]!;
          return UpdateAction(
            oldValue: old,
            newValue: imagePath,
            set: (v) => imagePath = v,
          );
        }
        if (args["source"] != null) {
          ImageSource old = source;
          source = ImageSource.values.firstWhere(
              (e) => e.toString() == args["source"],
              orElse: () => ImageSource.asset);
          return UpdateAction(
            oldValue: old,
            newValue: source,
            set: (v) => source = v,
          );
        }
        if (args["fit"] != null) {
          BoxFit old = fit;
          fit = BoxFit.values.firstWhere((e) => e.toString() == args["fit"],
              orElse: () => BoxFit.cover);
          return UpdateAction(
            oldValue: old,
            newValue: fit,
            set: (v) => fit = v,
          );
        }
        return null;
    }
    return super.handleAction(action, args);
  }

  @override
  String get label => "Image";
}

@notifier
class IconElement extends LeafElement {
  @notify
  IconData _icon;

  @notify
  Variable<Color> _color = ConstantVariable(Colors.black);

  /// [IconElement] is a [UIElement] that displays an icon.
  IconElement({
    IconData icon = LucideIcons.star,
    required super.root,
    super.parent,
  }) : _icon = icon;

  factory IconElement.from(UIElement element,
          {IconData icon = LucideIcons.star}) =>
      IconElement(
        icon: icon,
        root: element.root,
        parent: element.parent,
      )..copy(element);

  @override
  Widget getContent() {
    return Icon(
      icon,
      size: min(size.width.renderValue ?? 24, size.height.renderValue ?? 24),
      color: color.value,
    );
  }

  @override
  void copy(UIElement other) {
    super.copy(other);
    if (other is IconElement) {
      icon = other.icon;
      color = other.color;
    }
  }

  @override
  LeafElement clone({ElementRoot? root, ElementContainer? parent}) =>
      IconElement(
        icon: icon,
        root: root ?? this.root,
        parent: parent ?? this.parent,
      )..copy(this);

  @override
  String get label => "Icon";

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "leaf": {
        "type": "icon",
        "icon": icon.codePoint,
        "color": color.toString(),
      }
    };
  }

  IconElement.fromJson(
      Map<String, dynamic> json, ElementRoot root, ElementContainer? parent)
      : _icon = IconData(int.parse(json['leaf']['icon']),
            fontFamily: 'LucideIcons'),
        super.fromJson(json, root, parent) {
    Map<String, dynamic> leaf = json['leaf'];
    _color = VariableParser.parse<Color>(leaf['color'], root,
        notifyListeners: notifyListeners);
  }

  @override
  UpdateAction? setValue(String property, String value) {
    switch (property) {
      case "icon":
        int? codePoint = findCodePoint(value);
        if (codePoint == null || icon.codePoint == codePoint) return null;
        var old = icon;
        icon = IconData(codePoint, fontFamily: 'LucideIcons');
        return UpdateAction(
          oldValue: old,
          newValue: icon,
          set: (v) => icon = v,
        );
      case "color":
        var newValue = VariableParser.parse<Color>(value, root,
            notifyListeners: notifyListeners);
        if (color == newValue) return null;
        var old = color;
        color = newValue;
        return UpdateAction(
          oldValue: old,
          newValue: color,
          set: (v) => color = v,
        );
    }
    return super.setValue(property, value);
  }

  @override
  MyAction? handleAction(String action, Map<String, String> args) {
    switch (action) {
      case "setIcon":
        if (args["icon"] != null) {
          int? codePoint = findCodePoint(args["icon"] ?? "star");
          if (codePoint == null || icon.codePoint == codePoint) return null;
          var old = icon;
          icon = IconData(codePoint, fontFamily: 'LucideIcons');
          return UpdateAction(
            oldValue: old,
            newValue: icon,
            set: (v) => icon = v,
          );
        }
        if (args["color"] != null) {
          var newValue = VariableParser.parse<Color>(
              args["color"] ?? color.toString(), root,
              notifyListeners: notifyListeners);
          if (color == newValue) return null;
          var old = color;
          color = newValue;
          return UpdateAction(
            oldValue: old,
            newValue: color,
            set: (v) => color = v,
          );
        }
        return null;
    }
    return super.handleAction(action, args);
  }
}
