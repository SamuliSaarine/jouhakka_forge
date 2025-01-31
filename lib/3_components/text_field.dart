import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class MyNumberField<T extends num> extends StatefulWidget {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(8));

  final TextEditingController controller;
  final String? hintText;
  final void Function(T value) onChanged;
  final Color? textColor;
  const MyNumberField({
    super.key,
    required this.controller,
    this.hintText,
    this.textColor,
    required this.onChanged,
  });

  @override
  State<MyNumberField<T>> createState() => _MyNumberFieldState<T>();
}

class _MyNumberFieldState<T extends num> extends State<MyNumberField<T>> {
  static final List<TextInputFormatter> _allowDouble = [
    FilteringTextInputFormatter(RegExp(r'[0-9.]'), allow: true)
  ];

  static final List<TextInputFormatter> _allowInt = [
    FilteringTextInputFormatter.digitsOnly
  ];

  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onHover: (event) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) => setState(() => _isHovering = false),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.all(8),
          isDense: true,
          filled: true,
          fillColor: MyColors.mildDifference,
          enabledBorder: OutlineInputBorder(
            borderSide: _isHovering
                ? const BorderSide(color: MyColors.lighterCharcoal, width: 1.5)
                : BorderSide.none,
            borderRadius: MyNumberField._radius,
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: MyColors.lighterBlue, width: 2),
            borderRadius: MyNumberField._radius,
          ),
        ),
        onChanged: (value) {
          try {
            T parsed = num.parse(value) as T;
            widget.onChanged(parsed);
          } catch (e) {
            debugPrint("Invalid value: $value. Error: $e");
          }
        },
        keyboardType: TextInputType.number,
        inputFormatters: T == int ? _allowInt : _allowDouble,
        style:
            TextStyle(color: widget.textColor ?? MyColors.dark, fontSize: 14),
        cursorColor: MyColors.dark,
      ),
    );
  }
}
