import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HardwareKeyboardListener extends StatefulWidget {
  final LogicalKeyboardKey sourceKey;
  final Widget Function(bool isPressed) builder;

  /// Assign a [ValueNotifier] to the `source` parameter.
  ///
  /// `builder` will rebuild whenever the value of the source changes.
  const HardwareKeyboardListener({
    super.key,
    required this.sourceKey,
    required this.builder,
  });

  @override
  HardwareKeyboardListenerState createState() =>
      HardwareKeyboardListenerState();
}

class HardwareKeyboardListenerState extends State<HardwareKeyboardListener> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _isPressed =
        HardwareKeyboard.instance.isLogicalKeyPressed(widget.sourceKey);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event.logicalKey == widget.sourceKey) {
      if (event is KeyDownEvent && !_isPressed) {
        setState(() {
          _isPressed = true;
        });
      } else if (event is KeyUpEvent && _isPressed) {
        setState(() {
          _isPressed = false;
        });
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_isPressed);
  }
}
