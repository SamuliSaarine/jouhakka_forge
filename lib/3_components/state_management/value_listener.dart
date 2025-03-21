import 'package:flutter/material.dart';

class ValueListener<T> extends StatefulWidget {
  final ValueNotifier<T> source;
  final bool Function(T value)? condition;
  final Widget Function(T value) builder;

  /// Assign a [ValueNotifier] to the `source` parameter.
  ///
  /// `builder` will rebuild whenever the value of the source changes.
  const ValueListener({
    super.key,
    required this.source,
    required this.builder,
    this.condition,
  });

  @override
  ValueListenerState<T> createState() => ValueListenerState<T>();
}

class ValueListenerState<T> extends State<ValueListener<T>> {
  late ValueNotifier<T> _source;

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    _source.addListener(_onValueChanged);
  }

  @override
  void didUpdateWidget(covariant ValueListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the source has changed, reattach the listener to the new source
    if (widget.source != oldWidget.source) {
      _source.removeListener(_onValueChanged);
      _source = widget.source;
      _source.addListener(_onValueChanged);
    }
  }

  void _onValueChanged() {
    if (widget.condition != null && !widget.condition!(_source.value)) return;
    setState(() {});
  }

  @override
  void dispose() {
    _source.removeListener(_onValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_source.value);
  }
}
