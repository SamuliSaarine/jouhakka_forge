import 'package:flutter/material.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';

class MyTooltip extends StatefulWidget {
  final String message;
  final int millisecondsToWait;
  final Widget child;
  const MyTooltip(
    this.message, {
    super.key,
    this.millisecondsToWait = 500,
    required this.child,
  });

  @override
  State<MyTooltip> createState() => _MyTooltipState();
}

class _MyTooltipState extends State<MyTooltip> {
  bool _isHovering = false;
  bool _isShown = false;
  late Offset _position;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (event) async {
        _isHovering = true;
        _position = event.position;
        await Future.delayed(Duration(milliseconds: widget.millisecondsToWait));
        if (_isHovering && !_isShown) {
          _isShown = true;
          if (context.mounted) {
            Offset? offset = _position + const Offset(10, -40);
            ContextPopup.open(
              context,
              clickPosition: offset,
              secondary: true,
              child: _buildTooltip(),
            );
          }
        }
      },
      onHover: (event) => _position = event.position,
      onExit: (event) {
        _isHovering = false;
        if (_isShown) {
          ContextPopup.closeSecondary();
          _isShown = false;
        }
      },
      child: widget.child,
    );
  }

  Widget _buildTooltip() {
    return MouseRegion(
      opaque: false,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
