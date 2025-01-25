import 'package:flutter/material.dart';

class ChangeListener<T extends ChangeNotifier> extends StatefulWidget {
  final T source;
  final bool Function()? condition;
  final Widget Function() builder;

  /// Put a model that extends [ChangeNotifier] in the `source` parameter.
  ///
  /// `Builder` will rebuild whenever you call `notifyListeners()` on the source.
  const ChangeListener({
    super.key,
    required this.source,
    required this.builder,
    this.condition,
  });

  @override
  ChangeListenerState<T> createState() => ChangeListenerState<T>();
}

class ChangeListenerState<T extends ChangeNotifier>
    extends State<ChangeListener<T>> {
  late T _source;

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    _source.addListener(_onValueChanged);
  }

  @override
  void didUpdateWidget(covariant ChangeListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the source has changed, reattach the listener to the new source
    if (widget.source != oldWidget.source) {
      _source.removeListener(_onValueChanged);
      _source = widget.source;
      _source.addListener(_onValueChanged);
    }
  }

  void _onValueChanged() {
    if (widget.condition != null && !widget.condition!()) return;
    setState(() {});
  }

  @override
  void dispose() {
    _source.removeListener(_onValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder();
  }
}
