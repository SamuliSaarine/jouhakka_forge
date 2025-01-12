import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

class TextElement extends UIElement {
  String text;
  Color color;
  double fontSize;
  FontWeight fontWeight;

  TextElement(
      {this.text = "",
      this.color = Colors.black,
      this.fontSize = 16,
      this.fontWeight = FontWeight.normal,
      required super.root,
      super.parent});
}

enum ImageSource { asset, network }

class ImageElement extends UIElement {
  String imagePath;
  ImageSource source;
  BoxFit fit;
  Alignment alignment;

  ImageElement(
      {this.imagePath = "images/placeholder.png",
      this.source = ImageSource.asset,
      this.fit = BoxFit.fill,
      this.alignment = Alignment.center,
      required super.root,
      super.parent});
}
