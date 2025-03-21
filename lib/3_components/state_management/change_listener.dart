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

class ManyChangeListeners extends StatefulWidget {
  final List<ChangeNotifier> sources;
  final bool Function()? condition;
  final Widget Function() builder;

  const ManyChangeListeners({
    super.key,
    required this.sources,
    required this.builder,
    this.condition,
  });

  @override
  ManyChangeListenersState createState() => ManyChangeListenersState();
}

class ManyChangeListenersState extends State<ManyChangeListeners> {
  late List<ChangeNotifier> _sources;

  @override
  void initState() {
    super.initState();
    _sources = widget.sources;
    for (var source in _sources) {
      source.addListener(_onValueChanged);
    }
  }

  @override
  void didUpdateWidget(covariant ManyChangeListeners oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sources != oldWidget.sources) {
      for (var source in oldWidget.sources) {
        source.removeListener(_onValueChanged);
      }
      _sources = widget.sources;
      for (var source in _sources) {
        source.addListener(_onValueChanged);
      }
    }
  }

  void _onValueChanged() {
    if (widget.condition != null && !widget.condition!()) return;
    setState(() {});
  }

  @override
  void dispose() {
    for (var source in _sources) {
      source.removeListener(_onValueChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder();
  }
}
