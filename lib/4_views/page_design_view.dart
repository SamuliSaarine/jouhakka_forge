import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/canvas.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/3_components/element/element_builder_interface.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/4_views/inspector_view.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class PageDesignView extends StatefulWidget {
  final UIPage page;
  const PageDesignView(this.page, {super.key});

  static final Map<int, double> scrollStates = {};

  void disposeScrollStates() {
    scrollStates.clear();
  }

  @override
  State<PageDesignView> createState() => _PageDesignViewState();
}

class _PageDesignViewState extends State<PageDesignView> {
  late HoldOrToggle _containerEditorController;
  DateTime? _lastTimeShiftDown;
  late GlobalKey _bodyKey;

  Resolution get resolution => Session.currentResolution.value;

  UIElement get body => widget.page.body;

  late FocusNode myNode;

  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    widget.disposeScrollStates();
    myNode = FocusNode();
    myNode.requestFocus();
    _containerEditorController = HoldOrToggle(false);
    widget.page.body
      ..width.fixed(resolution.width)
      ..height.fixed(resolution.height);

    _widthController = TextEditingController(text: resolution.width.toString());
    _heightController =
        TextEditingController(text: resolution.height.toString());
    Session.selectedElement.value = widget.page.body;

    _bodyKey = GlobalKey();
  }

  @override
  void didUpdateWidget(covariant PageDesignView oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("Widget updated");
    myNode.requestFocus();
    if (oldWidget.page != widget.page) {
      oldWidget.disposeScrollStates();
      widget.page.body
        ..width.fixed(resolution.width)
        ..height.fixed(resolution.height);
      Session.selectedElement.value = widget.page.body;
      _bodyKey = GlobalKey();
    }
  }

  @override
  void dispose() {
    widget.disposeScrollStates();
    myNode.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: myNode,
            autofocus: true,
            onKeyEvent: (event) {
              try {
                if (event.logicalKey == LogicalKeyboardKey.shiftLeft) {
                  if (event is KeyDownEvent) {
                    debugPrint("Shift Down");
                    if (_lastTimeShiftDown != null &&
                        DateTime.now().difference(_lastTimeShiftDown!) <
                            const Duration(milliseconds: 500)) {
                      _containerEditorController.toggle();
                    } else {
                      _containerEditorController.hold();
                    }
                    _lastTimeShiftDown = DateTime.now();
                  } else if (event is KeyUpEvent) {
                    debugPrint("Shift Up");
                    _containerEditorController.release();
                  }
                } else if (event.logicalKey == LogicalKeyboardKey.controlLeft) {
                  if (event is KeyDownEvent) {
                    Session.ctrlDown.value = true;
                    debugPrint("Ctrl Down");
                  } else if (event is KeyUpEvent) {
                    Session.ctrlDown.value = false;
                    debugPrint("Ctrl Up");
                  }
                }
              } catch (e) {
                debugPrint("Error in key event: $e");
              }
            },
            child: Stack(
              children: [
                _canvas(),
                _topLeftBar(),
                _bottomRightBar(),
              ],
            ),
          ),
        ),
        InspectorView(widget.page),
      ],
    );
  }

  Widget _canvas() {
    try {
      Resolution res = body.getResolution() ?? resolution;
      return InteractiveCanvas(
        resolution: res,
        padding: res.height * 0.16,
        onCanvasTap: () {
          Session.selectedElement.value = null;
          if (!myNode.hasPrimaryFocus) {
            myNode.requestFocus();
          }
        },
        child: RepaintBoundary(
          child: ChangeListener(
              source: _containerEditorController,
              builder: () {
                try {
                  return ElementBuilderInterface(
                    globalKey: _bodyKey,
                    element: widget.page.body,
                    root: widget.page,
                    showContainerEditor: _containerEditorController.xor,
                    onBodyChanged: (element, _) {
                      debugPrint("Body changed");
                      setState(() {
                        widget.page.body = element;
                      });
                    },
                  );
                } catch (e) {
                  debugPrint("Error in canvas: $e");
                  return const ColoredBox(color: Colors.red);
                }
              }),
        ),
      );
    } catch (e) {
      debugPrint("Error in canvas: $e");
      return const ColoredBox(color: Colors.red);
    }
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
          children: [
            ChangeListener(
                source: _containerEditorController,
                builder: () {
                  return MyIconButton(
                    icon: Icons.dashboard_customize_outlined,
                    tooltip:
                        "Toggle container editor (Hold shift to hold editor, double tap to toggle)",
                    decoration: decoration,
                    isSelected: _containerEditorController.xor,
                    primaryAction: (_) {
                      _containerEditorController.toggle();
                    },
                  );
                })
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
    if (_widthController.text != resolution.width.toString()) {
      _widthController.text = "${body.width.value ?? resolution.width}";
    }
    if (_heightController.text != resolution.height.toString()) {
      _heightController.text = "${body.height.value ?? resolution.height}";
    }
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
        child: FloatingBar(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("W: ", style: TextStyle(color: Colors.white)),
                  SizedBox(
                    width: 52,
                    child: MyNumberField<int>(
                      controller: _widthController,
                      hintText: "Width",
                      textColor: MyColors.light,
                      onChanged: (value) {
                        if (value < 10) return;

                        _updateResolution(Resolution(
                            width: value.toDouble(),
                            height: resolution.height));
                      },
                    ),
                  ),
                  Gap.w8,
                  const Text("H: ", style: TextStyle(color: Colors.white)),
                  SizedBox(
                    width: 52,
                    child: MyNumberField<int>(
                      controller: _heightController,
                      hintText: "Height",
                      textColor: MyColors.light,
                      onChanged: (value) {
                        if (value < 10) return;
                        _updateResolution(Resolution(
                            width: resolution.width, height: value.toDouble()));
                      },
                    ),
                  ),
                ],
              ),
            ),
            MyIconButton(
              icon: Icons.desktop_windows_outlined,
              decoration: decoration,
              isSelected: resolution == Resolution.fullHD,
              primaryAction: (_) {
                _updateResolution(Resolution.fullHD);
              },
            ),
            MyIconButton(
              icon: Icons.tablet_mac_outlined,
              decoration: decoration,
              isSelected: resolution == Resolution.ipad10,
              primaryAction: (_) {
                _updateResolution(Resolution.ipad10);
              },
            ),
            MyIconButton(
              icon: Icons.phone_android_outlined,
              decoration: decoration,
              isSelected: resolution == Resolution.iphone13,
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
      Session.currentResolution.value = resolution;
    });
  }
}
