import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/utility_models.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/2_services/shortcuts.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/layout/canvas.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/3_components/element/element_builder_interface.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/keyboard_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/4_views/inspector_view.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part "page_design_view_extension.dart";

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
  late HoldOrToggle _paddingController;
  DateTime? _lastTimePaddingDown;
  late GlobalKey _bodyKey;

  Resolution get resolution => Session.currentResolution.value;

  UIElement get body => widget.page.body;

  late final FocusNode myNode;

  late final TextEditingController _widthController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    widget.disposeScrollStates();

    myNode = FocusNode();
    myNode.requestFocus();

    widget.page.body
      ..width.fixed(resolution.width)
      ..height.fixed(resolution.height);

    _bodyKey = GlobalKey();

    _paddingController = HoldOrToggle(false);
    _paddingController.addListener(() {
      Session.extraPadding.value = _paddingController.xor;
    });
    _widthController = TextEditingController(text: resolution.width.toString());
    _heightController =
        TextEditingController(text: resolution.height.toString());
  }

  @override
  void didUpdateWidget(covariant PageDesignView oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("Widget updated");
    myNode.requestFocus();
    if (oldWidget.page != widget.page) {
      oldWidget.disposeScrollStates();
      _pageInit();
    }
  }

  void _pageInit() {
    widget.page.body
      ..width.fixed(resolution.width)
      ..height.fixed(resolution.height);
    _bodyKey = GlobalKey();
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: myNode,
            autofocus: true,
            onKeyEvent: _onKeyEvent,
            child: Stack(
              children: [
                _canvas(),
                _bottomLeftBar(),
                _bottomRightBar(),
              ],
            ),
          ),
        ),
        Focus(
            onFocusChange: (value) {
              if (!value) {
                myNode.requestFocus();
              }
            },
            child: InspectorView(widget.page)),
      ],
    );
  }

  Widget _canvas() {
    Resolution res = body.getResolution() ?? resolution;
    return InteractiveCanvasView(
      canvasResolution: res,
      onViewTap: () {
        Session.selectedElement.value = null;
        if (!myNode.hasPrimaryFocus) {
          myNode.requestFocus();
        }
      },
      canvasObject: RepaintBoundary(
        child: ChangeListener(
            source: widget.page,
            builder: () {
              try {
                return ElementBuilderInterface(
                  globalKey: _bodyKey,
                  element: widget.page.body,
                  onBodyChanged: (element, _) {
                    debugPrint("Body changed");
                    widget.page.body = element;
                  },
                );
              } catch (e) {
                debugPrint("Error in canvas: $e");
                return const ColoredBox(color: Colors.red);
              }
            }),
      ),
    );
  }

  Widget _bottomLeftBar() {
    const MyIconButtonDecoration decoration =
        MyIconButtonDecoration.onDarkBar12;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 40.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingBar(
              children: [
                ChangeListener(
                  source: _paddingController,
                  builder: () {
                    return MyIconButton(
                      icon: Icons.dashboard_customize_outlined,
                      tooltip:
                          "Toggle container editor (Hold shift to hold editor, double tap to toggle)",
                      decoration: decoration,
                      isSelected: _paddingController.xor,
                      primaryAction: (_) {
                        _paddingController.toggle();
                      },
                    );
                  },
                ),
              ],
            ),
            Gap.w8,
            ValueListener(
              source: Session.hoveredElement,
              builder: (hoveredElement) {
                if (hoveredElement != null) {
                  return FloatingBar(
                    decoration: const FloatingBarDecoration(
                      backgroundColor: MyColors.mediumDifference,
                      borderRadius: 12,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          hoveredElement.label,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: HardwareKeyboardListener(
                          sourceKey: LogicalKeyboardKey.shiftLeft,
                          builder: (isPressed) {
                            return Row(
                              children: [
                                Text(
                                    "Left click: ${isPressed ? "New child" : "Select"}\nRight click: ${isPressed ? "Pick child" : "Context menu"}",
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 12)),
                                if (isPressed)
                                  ValueListener(
                                      source: Session.addDirection,
                                      builder: (addDirection) {
                                        final IconData icon;
                                        switch (addDirection) {
                                          case AddDirection.top:
                                            icon = LucideIcons.arrowUp;
                                            break;
                                          case AddDirection.bottom:
                                            icon = LucideIcons.arrowDown;
                                            break;
                                          case AddDirection.left:
                                            icon = LucideIcons.arrowLeft;
                                            break;
                                          case AddDirection.right:
                                            icon = LucideIcons.arrowRight;
                                            break;
                                          default:
                                            icon = LucideIcons.dot;
                                        }
                                        return Icon(
                                          icon,
                                          color: Colors.black,
                                          size: 16,
                                        );
                                      })
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomRightBar() {
    Widget resNumberEditor() {
      if (_widthController.text != resolution.width.toString()) {
        _widthController.text = "${body.width.value ?? resolution.width}";
      }
      if (_heightController.text != resolution.height.toString()) {
        _heightController.text = "${body.height.value ?? resolution.height}";
      }
      return Padding(
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
                      width: value.toDouble(), height: resolution.height));
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
      );
    }

    Widget resSelectorButton(IconData icon, Resolution res) {
      return MyIconButton(
        icon: icon,
        decoration: MyIconButtonDecoration.onDarkBar12,
        isSelected: resolution == res,
        primaryAction: (_) {
          _updateResolution(res);
        },
      );
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
        child: FloatingBar(
          children: [
            resNumberEditor(),
            resSelectorButton(LucideIcons.monitor, Resolution.fullHD),
            resSelectorButton(LucideIcons.tablet, Resolution.ipad10),
            resSelectorButton(LucideIcons.smartphone, Resolution.iphone13),
          ],
        ),
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }
}
