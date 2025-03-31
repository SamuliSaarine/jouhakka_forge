import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jouhakka_forge/0_models/project.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/4_views/editor_view.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/icons/lucide_map.dart';
import 'package:web/web.dart' as web;
// Purpose of this app is to offer tools to quickly create responsive UI design for apps and websites.

const bool _debugPerformance = false;

void main() {
  if (_debugPerformance) {
    debugRepaintRainbowEnabled = true;
    debugProfileLayoutsEnabled = true;
    debugPaintSizeEnabled = true;
  }

  MyColors.darkMode.value = kIsWeb
      ? web.window.matchMedia('(prefers-color-scheme: dark)').matches
      : PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  debugPrint('Dark mode: ${MyColors.darkMode.value}');

  initializeFirstLetterIndexes();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'main_restoration_scope',
      home: ValueListener(
        source: MyColors.darkMode,
        builder: (context) {
          return ValueListener(
            source: Session.globalCursor,
            builder: (value) {
              return MouseRegion(
                cursor: value,
                child: EditorView(
                  Project.empty(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
