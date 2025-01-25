import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/idservice.dart';

/// [Project] holds all the data of the design project. It contains [UIPage]s and [UIComponent]s in [ElementRootFolder]s.
/// It also holds global variables. Think [Project] like an one app or one website.
class Project {
  final String id;
  String name;
  final ElementRootFolder<UIPage> pages =
      ElementRootFolder("Pages", parent: null, items: [UIPage.empty()]);
  final ElementRootFolder<UIComponent> components =
      ElementRootFolder("Components", parent: null);

  Project(this.name) : id = IDService.newID("pr");

  Map<String, dynamic> variables = {};

  factory Project.empty() {
    return Project("New Project");
  }
}
