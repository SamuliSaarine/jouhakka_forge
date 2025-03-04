# Jouhakka Forge

You can quickly generate getters and setters for fields in [ChangeNotifier]
 - Use annotation @notifier for the class and @notify for the field
 - In the terminal run: dart run build_runner build --delete-conflicting-outputs
 - filename.g.dart is generated. Do not modify that file.

If lucide_icons_flutter package updates, to get new icons do next steps:
 - cd tools
 - dart lucide_generator.dart [path to your LucideIcons package]\assets\info.json
 - lucide_map.dart is generated in tools folder, move that to correct location (project_root/lib/5_style/icons)