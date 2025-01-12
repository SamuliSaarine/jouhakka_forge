import 'package:flutter/material.dart';

class MyTitledIconButton extends StatefulWidget {
  final Function() onTap;

  final String title;
  final IconData icon;
  final String? tooltip;
  final InlineSpan? richTooltip;
  final double iconSize;
  final double fontSize;
  final double padding;
  final double borderRadius;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color backgroundHoverColor;

  const MyTitledIconButton({
    super.key,
    required this.onTap,
    required this.title,
    required this.icon,
    this.tooltip,
    this.richTooltip,
    this.iconSize = 24,
    this.fontSize = 8,
    this.padding = 4,
    this.borderRadius = 4,
    this.iconColor = Colors.black,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.transparent,
    this.backgroundHoverColor = const Color.fromARGB(121, 123, 123, 123),
  }) : assert(tooltip != null || richTooltip != null,
            "Either tooltip or richTooltip must be provided");

  @override
  State<MyTitledIconButton> createState() => _MyTitledIconButtonState();
}

class _MyTitledIconButtonState extends State<MyTitledIconButton> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (_) => startHover(),
      onExit: (_) => endHover(),
      child: Tooltip(
        message: widget.tooltip,
        richMessage: widget.richTooltip,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHover
                  ? widget.backgroundHoverColor
                  : widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startHover() {
    setState(() => _isHover = true);
  }

  void endHover() {
    setState(() => _isHover = false);
  }
}
