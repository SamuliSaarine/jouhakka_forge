import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/4_views/page_design_view.dart';
import 'package:jouhakka_forge/3_components/layout/side_bar.dart';

class EditorView extends StatefulWidget {
  final Project project;
  const EditorView(this.project, {super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  Project get project => widget.project;
  late Widget view;

  @override
  void initState() {
    Session.currentProject.value = project;
    UIPage? page = project.pages.first;
    if (page == null) {
      throw Exception("Project must have at least one page");
    }
    view = PageDesignView(page);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Row(
            children: [
              SideBar(
                onViewChange: (view) {
                  setState(() {
                    this.view = view;
                  });
                },
              ),
              Expanded(child: view),
            ],
          ),
        ));
  }
}
