import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/ui_element.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/canvas.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/3_components/element/element_builder_interface.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/4_views/inspector_view.dart';

class PageDesignView extends StatefulWidget {
  final UIPage page;
  const PageDesignView(this.page, {super.key});

  @override
  State<PageDesignView> createState() => _PageDesignViewState();
}

class _PageDesignViewState extends State<PageDesignView> {
  bool _holdContainerEditor = false;
  bool _toggleContainerEditor = false;
  DateTime? _lastTimeShiftDown;

  Resolution _resolution = Resolution.iphone13;
  UIElement get body => widget.page.body;

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.requestFocus();
    widget.page.body = UIElement(root: widget.page, parent: null)
      ..width = AxisSize.fixed(_resolution.width)
      ..height = AxisSize.fixed(_resolution.height)
      ..decoration =
          ElementDecoration(backgroundColor: widget.page.backgroundHex);
    Session.selectedElement.value = widget.page.body;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft) {
          if (event is KeyDownEvent) {
            if (_lastTimeShiftDown != null &&
                DateTime.now().difference(_lastTimeShiftDown!) <
                    const Duration(milliseconds: 500)) {
              setState(() {
                _toggleContainerEditor = !_toggleContainerEditor;
              });
            } else {
              setState(() {
                _holdContainerEditor = true;
              });
            }
            _lastTimeShiftDown = DateTime.now();
          } else if (event is KeyUpEvent) {
            setState(() {
              _holdContainerEditor = false;
            });
          }
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                _canvas(),
                _topLeftBar(),
                _bottomRightBar(),
              ],
            ),
          ),
          InspectorView(widget.page),
        ],
      ),
    );
  }

  Widget _canvas() {
    Resolution res = body.getResolution() ?? _resolution;
    debugPrint("Building PageDesignView");
    return InteractiveCanvas(
      resolution: res,
      padding: res.height * 0.16,
      child: RepaintBoundary(
        child: ElementBuilderInterface(
          globalKey: GlobalKey(), //ValueKey("${widget.page.body.hashCode}_i"),
          element: widget.page.body,
          root: widget.page,
          showContainerEditor: _toggleContainerEditor ^ _holdContainerEditor,
          onBodyChanged: (element, _) {
            debugPrint("Body changed");
            setState(() {
              widget.page.body = element;
            });
          },
        ),
      ),
    );
  }

  Widget _topLeftBar() {
    const MyIconButtonDecoration decoration = MyIconButtonDecoration(
      iconColor: InteractiveColorSettings(color: Colors.white),
      backgroundColor: InteractiveColorSettings(
        color: Colors.transparent,
        hoverColor: Color.fromARGB(75, 207, 207, 207),
        selectedColor: Color.fromARGB(75, 207, 207, 207),
      ),
      padding: 12,
      borderRadius: 0,
      size: 24,
    );
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 40.0),
        child: FloatingBar(
          backgroundColor: const Color.fromARGB(255, 41, 53, 59),
          borderRadius: 20,
          children: [
            MyIconButton(
              icon: Icons.dashboard_customize_outlined,
              tooltip:
                  "Toggle container editor (Hold shift to hold editor, double tap to toggle)",
              decoration: decoration,
              isSelected: _toggleContainerEditor ^ _holdContainerEditor,
              primaryAction: (_) {
                setState(() {
                  _toggleContainerEditor = !_toggleContainerEditor;
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _bottomRightBar() {
    const MyIconButtonDecoration decoration = MyIconButtonDecoration(
      iconColor: InteractiveColorSettings(color: Colors.white),
      backgroundColor: InteractiveColorSettings(
        color: Colors.transparent,
        hoverColor: Color.fromARGB(75, 207, 207, 207),
        selectedColor: Color.fromARGB(75, 207, 207, 207),
      ),
      padding: 12,
      borderRadius: 0,
      size: 24,
    );
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
        child: FloatingBar(
          backgroundColor: const Color.fromARGB(255, 41, 53, 59),
          borderRadius: 12,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (body.width.value ?? _resolution.width).toString(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  Text(
                    (body.height.value ?? _resolution.height).toString(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            MyIconButton(
              icon: Icons.desktop_windows_outlined,
              decoration: decoration,
              isSelected: _resolution == Resolution.fullHD,
              primaryAction: (_) {
                _updateResolution(Resolution.fullHD);
              },
            ),
            MyIconButton(
              icon: Icons.tablet_mac_outlined,
              decoration: decoration,
              isSelected: _resolution == Resolution.ipad10,
              primaryAction: (_) {
                _updateResolution(Resolution.ipad10);
              },
            ),
            MyIconButton(
              icon: Icons.phone_android_outlined,
              decoration: decoration,
              isSelected: _resolution == Resolution.iphone13,
              primaryAction: (_) {
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
