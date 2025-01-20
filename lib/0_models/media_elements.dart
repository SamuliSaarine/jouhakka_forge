import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';

//TODO: Test this element

class TextElement extends UIElement {
  String text;
  Color color;
  double fontSize;
  FontWeight fontWeight;
  TextAlign alignment;

  TextElement({
    this.text = "Placeholder",
    this.color = Colors.black,
    this.fontSize = 18,
    this.fontWeight = FontWeight.normal,
    this.alignment = TextAlign.center,
    required super.root,
    super.parent,
  });

  @override
  Widget getContent() {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}

enum ImageSource { asset, network }

//TODO: Test this element
class ImageElement extends UIElement {
  String imagePath;
  ImageSource source;
  BoxFit fit;
  Alignment alignment;

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
}
