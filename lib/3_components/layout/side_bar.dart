import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  final Function(Widget view) onViewChange;
  const SideBar({super.key, required this.onViewChange});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  //TODO: Navigate between pages and other systems
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 200, child: Placeholder());
  }
}
