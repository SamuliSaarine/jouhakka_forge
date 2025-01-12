import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';

class FloatingBar extends StatefulWidget {
  final InteractiveColorSettings backgroundColor;
  final InteractiveColorSettings iconColor;
  final double iconSize;
  final double iconPadding;
  final double borderRadius;
  final BoxShadow? shadow;
  final List<FloatingBarAction> options;
  final List<FloatingBarAction> actions;

  const FloatingBar({
    super.key,
    this.backgroundColor = const InteractiveColorSettings(color: Colors.white),
    this.iconColor = const InteractiveColorSettings(color: Colors.black),
    this.iconSize = 24,
    this.iconPadding = 8,
    this.borderRadius = 8,
    this.shadow = const BoxShadow(
      color: Color(0x28000000),
      spreadRadius: 1,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    this.options = const [],
    this.actions = const [],
  });

  @override
  State<FloatingBar> createState() => _FloatingBarState();
}

class _FloatingBarState extends State<FloatingBar> {
  int _selectedOption = 0;
  FloatingBarAction? _hoveredAction;

  @override
  void initState() {
    super.initState();
    if (widget.options.isEmpty && widget.actions.isEmpty) {
      throw Exception("FloatingBar cannot be empty");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor.color,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.shadow != null ? [widget.shadow!] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.options.length; i++)
                _button(widget.options[i], i),
              for (FloatingBarAction action in widget.actions)
                _button(action, -1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(FloatingBarAction action, int optionIndex) {
    bool isHovered = _hoveredAction == action;
    bool isOption = optionIndex > -1;
    bool isSelected = _selectedOption == optionIndex;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredAction = action),
      onExit: (_) => setState(() => _hoveredAction = null),
      child: Tooltip(
        message: action.tooltip,
        child: GestureDetector(
          onTap: () {
            debugPrint("Tapped ${action.tooltip}. Is option: $isOption");
            action.primaryAction();
            if (isOption) {
              setState(() => _selectedOption = optionIndex);
              debugPrint("Selected option: ${action.tooltip}");
            }
          },
          child: Container(
            color: widget.backgroundColor.getColor(isSelected, isHovered),
            padding: EdgeInsets.all(widget.iconPadding),
            child: Icon(
              action.icon,
              size: widget.iconSize,
              color: widget.iconColor.getColor(isSelected, isHovered),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingBarAction {
  final IconData icon;
  final String tooltip;
  final ShortcutActivator? shortcut;
  final Function() primaryAction;
  final Function()? secondaryAction;

  const FloatingBarAction({
    required this.icon,
    required this.tooltip,
    required this.primaryAction,
    this.secondaryAction,
    this.shortcut,
  });
}
