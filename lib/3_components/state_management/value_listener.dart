import 'package:flutter/material.dart';

class ValueListener<T> extends StatefulWidget {
  final ValueNotifier<T> source;
  final bool Function(T value)? condition;
  final Widget Function(T value) builder;

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
