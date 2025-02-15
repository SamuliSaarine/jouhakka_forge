import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';

part 'media_elements.g.dart';

//TODO: Test this element

@notifier
class TextElement extends UIElement {
  @notify
  String _text;
  @notify
  Color _color = Colors.black;
  @notify
  double _fontSize = 18;
  @notify
  FontWeight _fontWeight = FontWeight.normal;
  @notify
  Alignment _alignment = Alignment.center;

  /// [TextElement] is a [UIElement] that displays text.
  TextElement({
    String text = "Placeholder",
    required super.root,
    super.parent,
  }) : _text = text;

  factory TextElement.from(UIElement element, {String text = "Placeholder"}) =>
      TextElement(
        text: text,
        root: element.root,
        parent: element.parent,
      )..copy(element);

  @override
  Widget getContent() {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        textAlign: alignment.getTextAlignment(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
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
  UIElement clone({ElementRoot? root, UIElement? parent}) => TextElement(
        text: text,
        root: root ?? this.root,
        parent: parent ?? this.parent,
      )..copy(this);

  @override
  String get label => "Text";
}

enum ImageSource { asset, network }

//TODO: Test this element
@notifier
class ImageElement extends UIElement {
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
  UIElement clone({ElementRoot? root, UIElement? parent}) => ImageElement(
        imagePath: imagePath,
        root: root ?? this.root,
        parent: parent ?? this.parent,
      )..copy(this);

  @override
  String get label => "Image";
}

@notifier
class IconElement extends UIElement {
  @notify
  IconData _icon;

  @notify
  Color _color = Colors.black;

  /// [IconElement] is a [UIElement] that displays an icon.
  IconElement({
    IconData icon = LucideIcons.star,
    required super.root,
    super.parent,
    double? size = 24,
  }) : _icon = icon {
    if (size != null) {
      width.fixed(size);
      height.fixed(size);
    }
  }

  factory IconElement.from(UIElement element,
          {IconData icon = LucideIcons.star}) =>
      IconElement(
        icon: icon,
        root: element.root,
        parent: element.parent,
        size: min(element.width.value ?? 24, element.height.value ?? 24),
      )..copy(element);

  @override
  Widget getContent() {
    return Icon(
      icon,
      size: min(width.value ?? 24, height.value ?? 24),
      color: color,
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
  UIElement clone({ElementRoot? root, UIElement? parent}) => IconElement(
        icon: icon,
        root: root ?? this.root,
        parent: parent ?? this.parent,
        size: min(width.value ?? 24, height.value ?? 24),
      )..copy(this);

  @override
  String get label => "Icon";
}
