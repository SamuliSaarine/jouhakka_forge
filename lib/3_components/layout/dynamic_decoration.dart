import 'package:flutter/material.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class DynamicDecoration extends StatefulWidget {
  final Widget child;
  const DynamicDecoration({
    super.key,
    required this.child,
  });

  @override
  State<DynamicDecoration> createState() => _DynamicDecorationState();
}

class _DynamicDecorationState extends State<DynamicDecoration> {
  @override
  Widget build(BuildContext context) {
    return ValueListener(
      source: Session.extraPadding,
      builder: (apply) {
        if (apply) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
                width: 0.5,
              ),
            ),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}
