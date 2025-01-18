import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/canvas.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/3_components/element/element_builder_interface.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';

class PageDesignView extends StatefulWidget {
  final UIPage page;
  const PageDesignView(this.page, {super.key});

  @override
  State<PageDesignView> createState() => _PageDesignViewState();
}

class _PageDesignViewState extends State<PageDesignView> {
  DesignMode _mode = DesignMode.wireframe;
  Resolution _resolution = Resolution.iphone13;
  UIElement get body => widget.page.body;

  @override
  void initState() {
    super.initState();
    widget.page.body = UIElement(root: widget.page, parent: null)
      ..width = AxisSize.fixed(_resolution.width)
      ..height = AxisSize.fixed(_resolution.height)
      ..decoration =
          ElementDecoration(backgroundColor: widget.page.backgroundHex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _canvas(),
        _topBar(),
        _cornerBar(),
      ],
    );
  }

  Widget _canvas() {
    Resolution res = body.getResolution() ?? _resolution;
    debugPrint("Building PageDesignView");
    return InteractiveCanvas(
      resolution: res,
      padding: res.height * 0.16,
      child: switch (_mode) {
        DesignMode.wireframe => RepaintBoundary(
            child: ElementBuilderInterface(
              globalKey:
                  GlobalKey(), //ValueKey("${widget.page.body.hashCode}_i"),
              element: widget.page.body,
              root: widget.page,
              onBodyChanged: (element, _) {
                debugPrint("Body changed");
                setState(() {
                  widget.page.body = element;
                });
              },
            ),
          ),
        DesignMode.design => widget.page.asWidget(),
        DesignMode.prototype =>
          throw UnimplementedError("Prototype mode not implemented"),
      },
    );
  }

  Widget _topBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: FloatingBar(
          backgroundColor: InteractiveColorSettings(
              color: Colors.white.withOpacity(0.6),
              hoverColor: Colors.grey[200]!.withOpacity(0.8),
              selectedColor: Colors.grey[500]!.withOpacity(0.4)),
          borderRadius: 20,
          iconPadding: 12,
          iconSize: 24,
          options: [
            FloatingBarAction(
              icon: Icons.dashboard_outlined,
              tooltip: "Wireframe",
              shortcut: const CharacterActivator("w"),
              primaryAction: () {
                setState(() {
                  _mode = DesignMode.wireframe;
                });
              },
            ),
            FloatingBarAction(
              icon: Icons.brush_outlined,
              tooltip: "Design",
              shortcut: const CharacterActivator("d"),
              primaryAction: () {
                setState(() {
                  _mode = DesignMode.design;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerBar() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
        child: FloatingBar(
          backgroundColor: InteractiveColorSettings(
              color: Colors.white.withOpacity(0.5),
              hoverColor: Colors.grey[200]!,
              selectedColor: Colors.grey[400]!.withOpacity(0.5)),
          borderRadius: 12,
          iconPadding: 16,
          iconSize: 20,
          custom: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (body.width.value ?? _resolution.width).toString(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  (body.height.value ?? _resolution.height).toString(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          options: [
            //Desktop, Tablet, Mobile
            FloatingBarAction(
              icon: Icons.desktop_windows_outlined,
              tooltip: "Desktop",
              shortcut: const CharacterActivator("1"),
              primaryAction: () {
                _updateResolution(Resolution.fullHD);
              },
            ),
            FloatingBarAction(
              icon: Icons.tablet_mac_outlined,
              tooltip: "Tablet",
              shortcut: const CharacterActivator("2"),
              primaryAction: () {
                _updateResolution(Resolution.ipad10);
              },
            ),
            FloatingBarAction(
              icon: Icons.phone_android_outlined,
              tooltip: "Mobile",
              shortcut: const CharacterActivator("3"),
              primaryAction: () {
                _updateResolution(Resolution.iphone13);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateResolution(Resolution resolution) {
    UIElement body = widget.page.body;
    body.width.value = resolution.width;
    body.height.value = resolution.height;
    setState(() {
      _resolution = resolution;
    });
  }
}
