import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/a_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/layout/context_menu.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/layout/inspector_boxes.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

extension ElementContainerEditor on ElementContainer {
  Widget getEditor() {
    return HeadPropertyBox(
      title: "Content",
      tip: "Container content",
      contextMenuItems: [
        ContextMenuItem(
          "Delete",
          action: (_) {
            element.content.value = null;
          },
        ),
      ],
      children: [
        ChangeListener(
          source: this,
          builder: () {
            return PropertyFieldBox(
              title: "Padding",
              tip: "Apply padding around content",
              contextMenuItems: const [],
              content: padding.getEditor(
                element,
                (padding) {
                  this.padding = padding;
                },
                notifyListeners,
              ),
            );
          },
        ),
        type.getEditor(
          onScrollEnable: (axis) {
            for (UIElement child in children) {
              if (axis == Axis.horizontal &&
                  child.size.width is ExpandingSize) {
                child.size.width =
                    ControlledSize.constant(child.size.width.renderValue!);
              } else if (axis == Axis.vertical &&
                  child.size.height is ExpandingSize) {
                child.size.heightToConstant();
              }
            }
          },
          switchType: (type) {
            if (type.runtimeType == this.type.runtimeType) return;
            this.type = type;
          },
        ),
      ],
    );
  }
}

extension ContainerElementEditor on ElementContainerType {
  Widget getEditor(
      {required void Function(Axis axis) onScrollEnable,
      required void Function(ElementContainerType type) switchType}) {
    return ChangeListener(
        source: this,
        builder: () {
          return SubPropertyBox(
            sideChild: this is SingleChildElementType
                ? null
                : Column(
                    children: [
                      MyIconButton(
                        icon: LucideIcons.rows2,
                        isSelected: this is FlexElementType,
                        primaryAction: (details) {
                          switchType(FlexElementType(Axis.vertical));
                        },
                      ),
                    ],
                  ),
            title: label,
            tip: "Container properties",
            contextMenuItems: const [],
            children: [
              _scrollChoice(onScrollEnable),
              _fromType(),
            ],
          );
        });
  }

  Widget _fromType() {
    if (this is SingleChildElementType) {
      return _singleChildEditor(this as SingleChildElementType);
    } else if (this is FlexElementType) {
      return _flexEditor(this as FlexElementType);
    } else {
      return const Text("Unsupported container type");
    }
  }

  Widget _scrollChoice(void Function(Axis axis) onScrollEnable) {
    return FloatingBar(children: [
      MyIconButton(
        icon: LucideIcons.lock,
        tooltip: "No scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar8,
        isSelected: scroll == null,
        primaryAction: (_) {
          scroll = null;
        },
      ),
      MyIconButton(
        icon: LucideIcons.moveVertical,
        tooltip: "Vertical scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar8,
        isSelected: scroll == Axis.vertical,
        primaryAction: (_) {
          onScrollEnable(Axis.vertical);
          scroll = Axis.vertical;
        },
      ),
      MyIconButton(
        icon: LucideIcons.moveHorizontal,
        tooltip: "Horizontal scroll",
        size: 14,
        decoration: MyIconButtonDecoration.onDarkBar8,
        isSelected: scroll == Axis.horizontal,
        primaryAction: (_) {
          onScrollEnable(Axis.horizontal);
          scroll = Axis.horizontal;
        },
      ),
    ]);
  }

  Widget _singleChildEditor(SingleChildElementType type) =>
      type.alignment.getEditor(
        (alignment) {
          type.alignment = alignment;
        },
      );

  Widget _flexEditor(FlexElementType type) {
    bool isVertical = type.direction == Axis.vertical;
    return Column(
      children: [
        FloatingBar(
          children: [
            MyIconButton(
              icon: LucideIcons.arrowDown,
              size: 14,
              decoration: MyIconButtonDecoration.onDarkBar8,
              isSelected: type.direction == Axis.vertical,
              primaryAction: (_) {
                type.direction = Axis.vertical;
              },
            ),
            MyIconButton(
              icon: LucideIcons.arrowRight,
              size: 14,
              decoration: MyIconButtonDecoration.onDarkBar8,
              isSelected: type.direction == Axis.horizontal,
              primaryAction: (_) {
                type.direction = Axis.horizontal;
              },
            ),
          ],
        ),
        Column(
          children: [
            //Main axis alignment
            FloatingBar(
              children: [
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignStartVertical
                      : LucideIcons.alignStartHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected: type.mainAxisAlignment == MainAxisAlignment.start,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.start;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignEndVertical
                      : LucideIcons.alignEndHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected: type.mainAxisAlignment == MainAxisAlignment.end,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.end;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignCenterVertical
                      : LucideIcons.alignCenterHorizontal,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.center,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.center;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignVerticalSpaceAround
                      : LucideIcons.alignHorizontalSpaceAround,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.spaceAround,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.spaceAround;
                  },
                ),
                MyIconButton(
                  icon: isVertical
                      ? LucideIcons.alignVerticalSpaceBetween
                      : LucideIcons.alignHorizontalSpaceBetween,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected:
                      type.mainAxisAlignment == MainAxisAlignment.spaceBetween,
                  primaryAction: (_) {
                    type.mainAxisAlignment = MainAxisAlignment.spaceBetween;
                  },
                ),
              ],
            ),
            //Cross axis alignment
            FloatingBar(children: [
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignStartHorizontal
                    : LucideIcons.alignStartVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar8,
                isSelected: type.crossAxisAlignment == CrossAxisAlignment.start,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.start;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignEndHorizontal
                    : LucideIcons.alignEndVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar8,
                isSelected: type.crossAxisAlignment == CrossAxisAlignment.end,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.end;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.alignCenterHorizontal
                    : LucideIcons.alignCenterVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar8,
                isSelected:
                    type.crossAxisAlignment == CrossAxisAlignment.center,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.center;
                },
              ),
              MyIconButton(
                icon: isVertical
                    ? LucideIcons.stretchHorizontal
                    : LucideIcons.stretchVertical,
                size: 14,
                decoration: MyIconButtonDecoration.onDarkBar8,
                isSelected:
                    type.crossAxisAlignment == CrossAxisAlignment.stretch,
                primaryAction: (_) {
                  type.crossAxisAlignment = CrossAxisAlignment.stretch;
                },
              ),
              if (!isVertical)
                MyIconButton(
                  icon: LucideIcons.baseline,
                  size: 14,
                  decoration: MyIconButtonDecoration.onDarkBar8,
                  isSelected:
                      type.crossAxisAlignment == CrossAxisAlignment.baseline,
                  primaryAction: (_) {
                    type.crossAxisAlignment = CrossAxisAlignment.baseline;
                  },
                ),
            ]),
          ],
        ),
      ],
    );
  }
}

extension ElementDecorationEditor on ElementDecoration {
  Widget getEditor(
    BuildContext context,
    UIElement element, {
    void Function()? onDelete,
  }) {
    //debugPrint("\nBuilding border editor: ${border.hashCode}\n");
    return ManyChangeListeners(
      sources: [border.hasValueNotifier],
      builder: () {
        List<(String, IconData, void Function())> properties = [
          if (border.value == null)
            (
              "Border",
              LucideIcons.square,
              () => border.value = MyBorder.all(Colors.black, 1)
            ),
        ];
        return HeadPropertyBox(
          title: "Decoration",
          tip: "Element decoration",
          contextMenuItems: [
            ContextMenuItem(
              "Delete",
              action: (_) {
                onDelete?.call();
              },
            ),
          ],
          children: [
            PropertyFieldBox(
              title: "Background:",
              tip: "Background color",
              contextMenuItems: const [],
              content: backgroundColor.getEditor(context, element,
                  hint: backgroundColor.variable is ConstantVariable
                      ? const TextFieldHint(HintType.prefix, text: "#")
                      : null),
            ),
            PropertyFieldBox(
              title: "Radius:",
              tip: "Border radius",
              contextMenuItems: const [],
              content: ChangeListener(
                  source: this,
                  builder: () {
                    return radius.getEditor(context, element,
                        (newRadius) => radius = newRadius, notifyListeners);
                  }),
            ),
            if (border.hasValueNotifier.value)
              border.getEditor(context, element),
            //margin.getEditor(context, element),
            if (properties.isNotEmpty)
              AddPropertiesEditor(properties: properties),
          ],
        );
      },
    );
  }
}

extension BorderEditor on MyBorder {
  Widget getEditor(UIElement element, void Function() onDelete) {
    String selected = "All";

    return StatefulBuilder(builder: (context, setState) {
      Widget header() {
        Widget selectMode(String label, IconData icon) {
          return MyIconButton(
            icon: icon,
            tooltip: label,
            decoration: MyIconButtonDecoration.onLightBackground,
            isSelected: selected == label,
            primaryAction: (_) {
              setState(() {
                selected = label;
              });
            },
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            selectMode("All", LucideIcons.square),
            selectMode("Top", LucideIcons.arrowUpToLine),
            selectMode("Bottom", LucideIcons.arrowDownToLine),
            selectMode("Right", LucideIcons.arrowRightToLine),
            selectMode("Left", LucideIcons.arrowLeftToLine),
          ],
        );

        /*return ClickDetector(
        primaryActionDown: (_) {
          toggleExpand();
        },
        builder: (hovering, _) => Row(
          children: [
            const Text("Border"),
            Icon(
              expandEditor
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
            ),
          ],
        ),
      );*/
      }

      return SubPropertyBox(
        title: "Stroke: $selected",
        tip: "Element border",
        contextMenuItems: [
          ContextMenuItem(
            "Delete",
            action: (_) {
              onDelete();
            },
          ),
        ],
        children: [
          header(),
          if (selected == "All" || selected == "Top")
            ...top.getEditor(
              context,
              element,
              onChanged: () {
                if (selected == "All") {
                  right.copy(top);
                  bottom.copy(top);
                  left.copy(top);
                }
              },
            ),
          if (selected == "Bottom") ...bottom.getEditor(context, element),
          if (selected == "Right") ...right.getEditor(context, element),
          if (selected == "Left") ...left.getEditor(context, element),
        ],
      );
    });
  }
}

extension BorderSideEditor on MyBorderSide {
  List<Widget> getEditor(BuildContext context, UIElement element,
      {void Function()? onChanged}) {
    return [
      PropertyFieldBox(
        title: "Width:",
        tip: "Border width",
        contextMenuItems: const [],
        content: width.getEditor(context, element,
            afterSet: () => onChanged?.call()),
      ),
      PropertyFieldBox(
        title: "Color:",
        tip: "Border color",
        contextMenuItems: const [],
        content: color.getEditor(context, element,
            afterSet: () => onChanged?.call()),
      ),
    ];
  }
}

extension RadiusEditor on MyRadius {
  Widget getEditor(BuildContext context, UIElement element,
      void Function(MyRadius) onChanged, void Function() notifyListeners) {
    bool selectAll = false;

    TextEditingController topLeftController =
        TextEditingController(text: topLeft.toString());
    TextEditingController topRightController =
        TextEditingController(text: topRight.toString());
    TextEditingController bottomRightController =
        TextEditingController(text: bottomRight.toString());
    TextEditingController bottomLeftController =
        TextEditingController(text: bottomLeft.toString());

    return StatefulBuilder(builder: (contex, setState) {
      void changeRadius(
          {Variable<double>? topLeft,
          Variable<double>? topRight,
          Variable<double>? bottomRight,
          Variable<double>? bottomLeft}) {
        if (selectAll) {
          onChanged(
            MyRadius.all(topLeft ??
                topRight ??
                bottomRight ??
                bottomLeft ??
                this.topLeft),
          );
          return;
        }
        onChanged(MyRadius(
          topLeft: topLeft ?? this.topLeft,
          topRight: topRight ?? this.topRight,
          bottomRight: bottomRight ?? this.bottomRight,
          bottomLeft: bottomLeft ?? this.bottomLeft,
        ));
      }

      Widget getEditor(
        Variable<double> current,
        IconData icon,
        TextEditingController controller,
        void Function(Variable<double>) onChanged,
      ) {
        return Expanded(
          child: MyTextField(
            controller: controller,
            isSelectedOverride: selectAll,
            onTap: () {
              setState(() {
                selectAll = HardwareKeyboard.instance.isShiftPressed;
              });
            },
            hint: TextFieldHint(HintType.prefix, icon: icon),
            onChanged: (value) {
              if (selectAll) {
                if (topLeftController.text != value) {
                  topLeftController.text = value;
                }
                if (topRightController.text != value) {
                  topRightController.text = value;
                }
                if (bottomRightController.text != value) {
                  bottomRightController.text = value;
                }
                if (bottomLeftController.text != value) {
                  bottomLeftController.text = value;
                }
              }
              return true;
            },
            onSubmitted: (value) {
              try {
                Variable<double> newVar = VariableParser.parse<double>(
                    value, element,
                    notifyListeners: notifyListeners);
                onChanged(newVar);
                return true;
              } catch (e) {
                debugPrint("Changing radius failed: $value. Error: $e");
                return false;
              }
            },
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getEditor(
            topLeft,
            LucideIcons.squareArrowUpLeft,
            topLeftController,
            (value) => changeRadius(topLeft: value),
          ),
          Gap.w4,
          getEditor(
            topRight,
            LucideIcons.squareArrowUpRight,
            topRightController,
            (value) => changeRadius(topRight: value),
          ),
          Gap.w4,
          getEditor(
            bottomRight,
            LucideIcons.squareArrowDownRight,
            bottomRightController,
            (value) => changeRadius(bottomRight: value),
          ),
          Gap.w4,
          getEditor(
            bottomLeft,
            LucideIcons.squareArrowDownLeft,
            bottomLeftController,
            (value) => changeRadius(bottomLeft: value),
          ),
        ],
      );
    });
  }
}
