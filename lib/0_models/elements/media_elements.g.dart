// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_elements.dart';

// **************************************************************************
// NotifierGenerator
// **************************************************************************

extension TextElementNotifyExtension on TextElement {
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    notifyListeners();
  }

  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    notifyListeners();
  }

  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    notifyListeners();
  }

  FontWeight get fontWeight => _fontWeight;
  set fontWeight(FontWeight value) {
    if (_fontWeight == value) return;
    _fontWeight = value;
    notifyListeners();
  }

  Alignment get alignment => _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    notifyListeners();
  }
}

extension ImageElementNotifyExtension on ImageElement {
  String get imagePath => _imagePath;
  set imagePath(String value) {
    if (_imagePath == value) return;
    _imagePath = value;
    notifyListeners();
  }

  ImageSource get source => _source;
  set source(ImageSource value) {
    if (_source == value) return;
    _source = value;
    notifyListeners();
  }

  BoxFit get fit => _fit;
  set fit(BoxFit value) {
    if (_fit == value) return;
    _fit = value;
    notifyListeners();
  }

  Alignment get alignment => _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    notifyListeners();
  }
}

extension IconElementNotifyExtension on IconElement {
  IconData get icon => _icon;
  set icon(IconData value) {
    if (_icon == value) return;
    _icon = value;
    notifyListeners();
  }

  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    notifyListeners();
  }
}
