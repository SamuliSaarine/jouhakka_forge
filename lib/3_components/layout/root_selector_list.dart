import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';

class RootSelectorList<T extends ElementRoot> extends StatelessWidget {
  final ElementRootFolder<T> rootFolder;
  final Function(T item) onSelection;

  const RootSelectorList(this.rootFolder,
      {super.key, required this.onSelection});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
