import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';

//TODO: Test this element

class TextElement extends UIElement {
  String text;
  Color color;
  double fontSize;
  FontWeight fontWeight;
  Alignment alignment;

  /// [TextElement] is a [UIElement] that displays text.
  TextElement({
    this.text = "Placeholder",
    this.color = Colors.black,
    this.fontSize = 18,
    this.fontWeight = FontWeight.normal,
    this.alignment = Alignment.center,
    required super.root,
    super.parent,
  });

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
  String get label => "Text";
}

enum ImageSource { asset, network }

//TODO: Test this element
class ImageElement extends UIElement {
  /// File path or URL of the image.
  String imagePath;

  /// Source of the image. Can be either an asset or a network image.
  ImageSource source;

  /// How the image should be fitted into the box.
  BoxFit fit;

  /// How the image should be aligned within its box.
  Alignment alignment;

  /// [ImageElement] is a [UIElement] that displays an image.
  ImageElement({
    this.imagePath = "images/placeholder.png",
    this.source = ImageSource.asset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    required super.root,
    super.parent,
  });

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
  String get label => "Image";
}
