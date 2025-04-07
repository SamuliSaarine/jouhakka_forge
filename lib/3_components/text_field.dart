import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/textstyles.dart';

class MyNumberField<T extends num> extends StatefulWidget {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(8));

  final TextEditingController controller;
  final String? hintText;
  final void Function(T value) onChanged;
  final TextStyle? textStyle;
  final void Function()? onTap;
  final Function()? onSubmitted;
  final bool isSelectedOverride;

  const MyNumberField({
    super.key,
    required this.controller,
    this.hintText,
    this.textStyle,
    this.isSelectedOverride = false,
    this.onTap,
    this.onSubmitted,
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
    OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderSide: _isHovering
          ? const BorderSide(color: MyColors.storm, width: 1.5)
          : BorderSide.none,
      borderRadius: MyNumberField._radius,
    );

    OutlineInputBorder focusedBorder = const OutlineInputBorder(
      borderSide: BorderSide(
        color: MyColors.lighterBlue,
        width: 2,
      ),
      borderRadius: MyNumberField._radius,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onHover: (event) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) => setState(() => _isHovering = false),
      child: TextField(
        onTap: widget.onTap,
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.all(8),
          isDense: true,
          filled: true,
          fillColor: MyColors.mildDifference,
          enabledBorder:
              widget.isSelectedOverride ? focusedBorder : enabledBorder,
          focusedBorder: focusedBorder,
        ),
        onChanged: (value) {
          try {
            T parsed = num.parse(value) as T;
            widget.onChanged(parsed);
          } catch (e) {
            debugPrint("Invalid value: $value. Error: $e");
          }
        },
        onSubmitted: (_) => widget.onSubmitted?.call(),
        keyboardType: TextInputType.number,
        inputFormatters: T == int ? _allowInt : _allowDouble,
        style: widget.textStyle ?? MyTextStyles.darkBody,
        cursorColor: MyColors.dark,
      ),
    );
  }
}

enum HintType { background, prefix, suffix }

class TextFieldHint {
  final String? text;
  final IconData? icon;
  final HintType type;
  const TextFieldHint(this.type, {this.text, this.icon})
      : assert((text == null) != (icon == null),
            "Either text or icon must be provided, but not both."),
        assert(type != HintType.background || icon == null,
            "Can't use icon with background hint.");
}

class MyTextField extends StatefulWidget {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(8));

  final TextEditingController controller;
  final TextFieldHint? hint;
  final bool Function(String value)? onChanged;
  final bool Function(String value)? onSubmitted;
  final void Function()? onTap;
  final TextStyle? textStyle;
  final bool isSelectedOverride;
  final bool expands;

  const MyTextField({
    super.key,
    required this.controller,
    this.hint,
    this.textStyle,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.isSelectedOverride = false,
    this.expands = false,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool _isHovering = false;
  bool _isValid = true;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderSide: _isValid
          ? _isHovering
              ? const BorderSide(color: MyColors.storm, width: 1.5)
              : BorderSide.none
          : const BorderSide(color: Colors.red, width: 2),
      borderRadius: MyTextField._radius,
    );

    OutlineInputBorder focusedBorder = const OutlineInputBorder(
      borderSide: BorderSide(
        color: MyColors.darkMint,
        width: 2,
      ),
      borderRadius: MyNumberField._radius,
    );

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
        expands: widget.expands,
        maxLines: widget.expands ? null : 1,
        minLines: widget.expands ? null : 1,
        onTap: widget.onTap,
        textAlignVertical: widget.expands ? TextAlignVertical.top : null,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: widget.hint?.type == HintType.background
              ? widget.hint!.text
              : null,
          prefixText:
              widget.hint?.type == HintType.prefix ? widget.hint?.text : null,
          prefixStyle: MyTextStyles.smallTip,
          prefixIcon:
              widget.hint?.type == HintType.prefix && widget.hint?.icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        widget.hint!.icon,
                        size: 16,
                        color: widget.isSelectedOverride
                            ? MyColors.darkMint
                            : MyColors.storm,
                      ),
                    )
                  : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          suffix: widget.hint?.type == HintType.suffix
              ? widget.hint?.icon == null
                  ? Text(
                      widget.hint!.text!,
                      style: MyTextStyles.smallTip,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        height: 30,
                        child: Center(
                          child: Icon(
                            widget.hint!.icon,
                            color: MyColors.dark,
                          ),
                        ),
                      ),
                    )
              : null,
          contentPadding: const EdgeInsets.all(6),
          isDense: true,
          filled: true,
          fillColor: MyColors.storm12,
          enabledBorder:
              widget.isSelectedOverride ? focusedBorder : enabledBorder,
          focusedBorder: focusedBorder,
        ),
        onChanged: (value) {
          if (widget.onChanged == null) return;
          bool isValid = widget.onChanged!(value);
          if (isValid != _isValid) {
            setState(() => _isValid = isValid);
          }
        },
        onSubmitted: (value) {
          if (widget.onSubmitted == null) return;
          bool isValid = widget.onSubmitted!(value);
          if (isValid != _isValid) {
            setState(() => _isValid = isValid);
          }
        },
        style: widget.textStyle ?? MyTextStyles.darkBody,
        cursorColor: MyColors.dark,
      ),
    );
  }
}
