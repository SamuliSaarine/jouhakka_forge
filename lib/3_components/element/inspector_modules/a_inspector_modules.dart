import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/buttons/my_text_button.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/element/inspector_modules/branch_inspector_modules.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart'
    show FloatingBar, FloatingBarDecoration;
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/layout/inspector_boxes.dart';
import 'package:jouhakka_forge/3_components/layout/my_color_picker.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/textstyles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _SizeControllerSet {
  late final TextEditingController? fixedController;
  late final TextEditingController? minController;
  late final TextEditingController? maxController;
  late final TextEditingController? flexController;

  _SizeControllerSet(AxisSize axis) {
    bool isControlled = axis is ControlledSize;
    fixedController = isControlled
        ? TextEditingController(text: axis.value.toString())
        : null;
    minController = !isControlled
        ? TextEditingController(text: (axis as AutomaticSize).min.toString())
        : null;
    maxController = !isControlled
        ? TextEditingController(text: (axis as AutomaticSize).max.toString())
        : null;
    flexController = !isControlled && axis is ExpandingSize
        ? TextEditingController(text: axis.flex.toString())
        : null;
  }
}

extension SizeEditor on SizeHolder {
  Widget getEditor(UIElement element) {
    if (element.parent == null) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "Size cannot be edited for root element",
              style: TextStyle(color: MyColors.storm),
            )),
      );
    }
    bool selectBoth = false;
    /* CONTROLLERS */
    _SizeControllerSet widthControllers = _SizeControllerSet(width);
    _SizeControllerSet heightControllers = _SizeControllerSet(height);

    Widget axisEditor(String title, Axis axis) {
      AxisSize axisSize = axis == Axis.vertical ? height : width;
      void Function(AxisSize) onChanged = axis == Axis.vertical
          ? (axisSize) => height = axisSize
          : (axisSize) => width = axisSize;
      bool allowShrink =
          (element is BranchElement && element.content.value != null) ||
              element is LeafElement;
      return PropertyFieldBox(
        title: title,
        tip: "Edit $title",
        contextMenuItems: const [],
        content: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FloatingBar(
                    decoration: FloatingBarDecoration.flatLightMode,
                    children: [
                      Expanded(
                        child: MyIconButton(
                          icon: axis == Axis.vertical
                              ? LucideIcons.foldVertical
                              : LucideIcons.foldHorizontal,
                          size: 20,
                          tooltip: allowShrink ? "Hug" : "No content to hug",
                          isEnabled: allowShrink,
                          decoration: MyIconButtonDecoration.onDarkBar8,
                          isSelected: axisSize is ShrinkingSize,
                          primaryAction: (_) {
                            axis == Axis.vertical
                                ? height = ShrinkingSize()
                                : width = ShrinkingSize();
                          },
                        ),
                      ),
                      SizedBox(height: 20, child: MyDividers.lightVertical),
                      Expanded(
                        child: MyIconButton(
                          icon: axis == Axis.vertical
                              ? LucideIcons.unfoldVertical
                              : LucideIcons.unfoldHorizontal,
                          size: 20,
                          tooltip: "Expand",
                          decoration: MyIconButtonDecoration.onDarkBar8,
                          isSelected: axisSize is ExpandingSize,
                          primaryAction: (_) {
                            axis == Axis.vertical
                                ? height = ExpandingSize()
                                : width = ExpandingSize();
                          },
                        ),
                      ),
                      SizedBox(height: 20, child: MyDividers.lightVertical),
                      Expanded(
                        child: MyIconButton(
                          icon: LucideIcons.ruler,
                          size: 20,
                          decoration: MyIconButtonDecoration.onDarkBar8,
                          isSelected: axisSize is ControlledSize,
                          primaryAction: (_) {
                            axis == Axis.vertical
                                ? height = ControlledSize.constant(
                                    axisSize.renderValue ?? 100)
                                : width = ControlledSize.constant(
                                    axisSize.renderValue ?? 100);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.w16,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: MyColors.storm),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    axisSize.renderValue?.toPrecisionOf2() ?? "unknown",
                    style: MyTextStyles.smallTip,
                  ),
                ),
                Gap.w16,
              ],
            ),
            Gap.h4,
            if (axisSize is ControlledSize)
              MyTextField(
                controller: axis == Axis.vertical
                    ? heightControllers.fixedController!
                    : widthControllers.fixedController!,
                onSubmitted: (value) {
                  try {
                    Variable<double> newVar = VariableParser.parse<double>(
                      value,
                      element,
                      notifyListeners: notifyListeners,
                    );
                    onChanged(ControlledSize(newVar));
                    return true;
                  } catch (e) {
                    debugPrint("Error parsing variable $value: $e");
                    return false;
                  }
                },
              ),
            if (axisSize is AutomaticSize)
              Row(
                children: [
                  Flexible(
                    child: MyTextField(
                      controller: axis == Axis.vertical
                          ? heightControllers.minController!
                          : widthControllers.minController!,
                      hint: const TextFieldHint(
                        HintType.prefix,
                        text: "Min ",
                      ),
                      onSubmitted: (value) {
                        try {
                          Variable<double> newVar =
                              VariableParser.parse<double>(value, element,
                                  notifyListeners: notifyListeners);

                          onChanged(axisSize.clone(min: newVar));

                          return true;
                        } catch (e) {
                          debugPrint("Error parsing variable $value: $e");
                          return false;
                        }
                      },
                    ),
                  ),
                  Gap.w4,
                  Flexible(
                    child: MyTextField(
                      controller: axis == Axis.vertical
                          ? heightControllers.maxController!
                          : widthControllers.maxController!,
                      hint: const TextFieldHint(
                        HintType.prefix,
                        text: "Max ",
                      ),
                      onSubmitted: (value) {
                        try {
                          Variable<double> newVar =
                              VariableParser.parse<double>(value, element,
                                  notifyListeners: notifyListeners);

                          onChanged(axisSize.clone(max: newVar));

                          return true;
                        } catch (e) {
                          debugPrint("Error parsing variable $value: $e");
                          return false;
                        }
                      },
                    ),
                  ),
                  if (axisSize is ExpandingSize) ...[
                    Gap.w4,
                    Flexible(
                      child: MyTextField(
                        controller: axis == Axis.vertical
                            ? heightControllers.flexController!
                            : widthControllers.flexController!,
                        hint: const TextFieldHint(
                          HintType.prefix,
                          text: "Flex ",
                        ),
                        onSubmitted: (value) {
                          try {
                            Variable<int> newVar = VariableParser.parse<int>(
                                value, element,
                                notifyListeners: notifyListeners);

                            onChanged(axisSize.clone(flex: newVar));

                            return true;
                          } catch (e) {
                            debugPrint("Error parsing variable $value: $e");
                            return false;
                          }
                        },
                      ),
                    ),
                  ]
                ],
              )
          ],
        ),
      );
    }

    return ChangeListener(
        source: this,
        builder: () {
          widthControllers = _SizeControllerSet(width);
          heightControllers = _SizeControllerSet(height);
          return Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                axisEditor("Width:", Axis.horizontal), //Width
                Gap.h4,
                MyDividers.lightHorizontal,
                Gap.h4,
                axisEditor("Height:", Axis.vertical), //Height
              ],
            ),
          );
        });
  }
}

extension VariableEditor<T> on VarField<T> {
  Widget getEditor(BuildContext context, UIElement element,
      {TextFieldHint? hint, void Function()? afterSet}) {
    final TextEditingController variableController =
        TextEditingController(text: variable.toString());

    return ChangeListener(
      source: this,
      builder: () {
        if (variableController.text != variable.toString()) {
          variableController.text = variable.toString();
        }
        Widget current = MyTextField(
          controller: variableController,
          hint: hint,
          onSubmitted: (value) {
            try {
              variable = VariableParser.parse<T>(value, element,
                  notifyListeners: notifyListeners);
              afterSet?.call();
              return true;
            } catch (e) {
              debugPrint("Error parsing variable $value: $e");
              return false;
            }
          },
        );

        if (T == Color) {
          current = (this as VarField<Color>)
              .getColorEditor(context, current, element, afterSet);
        }

        return current;
      },
    );
  }
}

extension ColorEditor on VarField<Color> {
  Widget getColorEditor(BuildContext context, Widget textField,
      UIElement element, void Function()? afterSet) {
    final TextEditingController opacityController =
        TextEditingController(text: "${(value).a * 100}%");

    bool onOpacitySubmitted(String value) {
      try {
        Variable<double> opacity = VariableParser.parse<double>(value, element,
            notifyListeners: notifyListeners);
        if (opacity.value < 0 || opacity.value > 1) {
          debugPrint("Opacity value must be between 0 and 100");
          return false;
        }
        if (variable is OverrideOpacityVariable) {
          if (opacity is ConstantVariable<double> &&
              opacity.value ==
                  (variable as OverrideOpacityVariable).color.value.a) {
            variable = (variable as OverrideOpacityVariable).color;
          } else {
            variable = OverrideOpacityVariable(
              (variable as OverrideOpacityVariable).color,
              opacity,
              notifyListeners,
            );
          }
        } else if (opacity is! ConstantVariable<double> ||
            opacity.value != this.value.a) {
          variable =
              OverrideOpacityVariable(variable, opacity, notifyListeners);
        }
        afterSet?.call();
        return true;
      } catch (e) {
        debugPrint("Error parsing opacity: $e");
        return false;
      }
    }

    void pickColor(Offset clickPosition) async {
      //Color? selectedColor;
      debugPrint("Color picker to: $clickPosition");
      ContextPopup.open(
        context,
        preferAlignment: Alignment.centerRight,
        clickPosition: clickPosition,
        child: MyColorPicker(
          initialColor: value,
          onColorChanged: (color) {
            variable = ConstantVariable<Color>(color) as Variable<Color>;
            afterSet?.call();
          },
        ),
      );
      //await ContextPopup.waitOnClose();
      /*if (selectedColor != null) {
        variable = ConstantVariable<Color>(selectedColor!) as Variable<Color>;
      }*/
    }

    final Widget selectedColorBox = ClickDetector(
      primaryActionUp: (details) => pickColor(details.globalPosition),
      builder: (hovered, pressed) {
        return DecoratedBox(
            decoration: BoxDecoration(
              color: value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovered ? MyColors.lightMint : MyColors.storm30,
                width: 2,
              ),
            ),
            child: const AspectRatio(aspectRatio: 1));
      },
    );

    final Widget textFields = Row(
      children: [
        Expanded(
          flex: 2,
          child: textField,
        ),
        Gap.w4,
        Flexible(
          flex: 1,
          child: MyTextField(
            controller: opacityController,
            onSubmitted: onOpacitySubmitted,
          ),
        ),
      ],
    );

    final Widget myPalette = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (Color color in [
            Colors.black,
            Colors.white,
            Colors.blue,
            Colors.green,
            Colors.red,
            Colors.yellow,
          ])
            ClickDetector(
              primaryActionUp: (_) {
                variable = ConstantVariable<Color>(color) as Variable<Color>;
                afterSet?.call();
              },
              builder: (hovered, pressed) {
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hovered ? MyColors.lightMint : MyColors.storm30,
                        width: 1,
                      ),
                    ),
                    child: const SizedBox(width: 24, height: 24),
                  ),
                );
              },
            )
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          selectedColorBox,
          Gap.w8,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                textFields,
                Gap.h2,
                myPalette,
              ],
            ),
          )
        ],
      ),
    );
  }
}

extension AlignmentEditor on Alignment {
  Widget getEditor(void Function(Alignment alignment) set) {
    Widget alignmentButton(Alignment alignment) {
      return MyIconButton(
        icon: Icons.circle,
        size: 14,
        decoration: const MyIconButtonDecoration(
          iconColor: InteractiveColorSettings(
              color: MyColors.storm,
              selectedColor: MyColors.lightMint,
              hoverColor: MyColors.lightMint),
        ),
        isSelected: alignment == this,
        primaryAction: (_) {
          set(alignment);
        },
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MyColors.slate,
        border: Border.all(color: MyColors.storm),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              alignmentButton(Alignment.topLeft),
              alignmentButton(Alignment.centerLeft),
              alignmentButton(Alignment.bottomLeft),
            ],
          ),
          Column(
            children: [
              alignmentButton(Alignment.topCenter),
              alignmentButton(Alignment.center),
              alignmentButton(Alignment.bottomCenter),
            ],
          ),
          Column(
            children: [
              alignmentButton(Alignment.topRight),
              alignmentButton(Alignment.centerRight),
              alignmentButton(Alignment.bottomRight),
            ],
          ),
        ],
      ),
    );
  }
}

extension OptionalPropertyEditor<T> on OptionalProperty<T> {
  Widget getEditor(
    BuildContext context,
    UIElement element,
  ) {
    if (T == MyPadding) {
      MyPadding initialPadding =
          value is MyPadding ? value as MyPadding : MyPadding.zero;
      return initialPadding.getEditor(
        element,
        (padding) {
          value = padding as T;
        },
        listener,
      );
    } else if (T == ElementDecoration) {
      return ValueListener(
        source: hasValueNotifier,
        builder: (hasValue) {
          if (hasValue) {
            assert(value != null, "Has value but value is null");
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                (value as ElementDecoration).getEditor(context, element,
                    onDelete: () {
                  value = null;
                }),
              ],
            );
          } else {
            return Center(
              child: MyTextButton(
                text: "+ Decoration",
                textStyle: MyTextStyles.smallTip,
                primaryAction: (_) {
                  value = ElementDecoration() as T;
                },
              ),
            );
          }
        },
      );
    } else if (T == MyBorder) {
      assert(value != null, "Do not create border editor if value is null");
      return (value as MyBorder).getEditor(element, () {
        value = null;
      });
    }

    return const Text("Unsupported type");
  }
}

extension MyPaddingEditor on MyPadding {
  Widget getEditor(UIElement element, void Function(MyPadding) onChanged,
      void Function() notifyListeners) {
    bool selectHorizontal = false;
    bool selectVertical = false;

    TextEditingController topController =
        TextEditingController(text: top.toString());
    TextEditingController bottomController =
        TextEditingController(text: bottom.toString());
    TextEditingController leftController =
        TextEditingController(text: left.toString());
    TextEditingController rightController =
        TextEditingController(text: right.toString());

    return StatefulBuilder(builder: (contex, setState) {
      void changePadding({
        Variable<double>? top,
        Variable<double>? bottom,
        Variable<double>? left,
        Variable<double>? right,
      }) {
        Variable<double>? all = (selectHorizontal && selectVertical)
            ? top ?? bottom ?? left ?? right
            : null;
        if (selectHorizontal) {
          debugPrint("Left: $left, Right: $right");
          left ??= right ??= all;
          right ??= left;
        }
        if (selectVertical) {
          debugPrint("Top: $top, Bottom: $bottom");
          top ??= bottom ??= all;
          bottom ??= top;
        }
        onChanged(MyPadding(
          top: top ?? this.top,
          bottom: bottom ?? this.bottom,
          left: left ?? this.left,
          right: right ?? this.right,
        ));
      }

      Widget getEditor(
        Variable<double> current,
        IconData icon,
        TextEditingController controller,
        Axis axis,
        void Function(Variable<double>) onChanged,
      ) {
        return Expanded(
          child: MyTextField(
            controller: controller,
            isSelectedOverride: axis == Axis.horizontal
                ? selectHorizontal
                : axis == Axis.vertical
                    ? selectVertical
                    : false,
            onTap: () {
              setState(() {
                if (HardwareKeyboard.instance.isShiftPressed) {
                  selectHorizontal = true;
                  selectVertical = true;
                } else if (HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed) {
                  selectHorizontal = axis == Axis.horizontal;
                  selectVertical = axis == Axis.vertical;
                } else {
                  selectHorizontal = false;
                  selectVertical = false;
                }
              });
            },
            hint: TextFieldHint(HintType.prefix, icon: icon),
            onChanged: (value) {
              if (selectVertical) {
                if (topController.text != value) {
                  topController.text = value;
                }
                if (bottomController.text != value) {
                  bottomController.text = value;
                }
              }
              if (selectHorizontal) {
                if (leftController.text != value) {
                  leftController.text = value;
                }
                if (rightController.text != value) {
                  rightController.text = value;
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
            top,
            LucideIcons.arrowUpToLine,
            topController,
            Axis.vertical,
            (value) => changePadding(top: value),
          ),
          Gap.w4,
          getEditor(
            bottom,
            LucideIcons.arrowDownToLine,
            bottomController,
            Axis.vertical,
            (value) => changePadding(bottom: value),
          ),
          Gap.w4,
          getEditor(
            left,
            LucideIcons.arrowLeftToLine,
            leftController,
            Axis.horizontal,
            (value) => changePadding(left: value),
          ),
          Gap.w4,
          getEditor(
            right,
            LucideIcons.arrowRightToLine,
            rightController,
            Axis.horizontal,
            (value) => changePadding(right: value),
          ),
        ],
      );
    });
  }
}

class AddPropertiesEditor extends StatelessWidget {
  final List<(String label, IconData icon, void Function() action)> properties;
  const AddPropertiesEditor({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    return PropertyFieldBox(
      title: "Add property:",
      tip: "Add a new property to edit element further",
      contextMenuItems: const [],
      content: Row(
        children: [
          for (var property in properties)
            propertyButton(property.$1, property.$2, property.$3),
        ],
      ),
    );
  }

  Widget propertyButton(String label, IconData icon, void Function() action) {
    return MyIconButton(
      icon: icon,
      size: 24,
      tooltip: label,
      decoration: const MyIconButtonDecoration(
        padding: 8,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: InteractiveColorSettings(color: MyColors.dark),
      ),
      primaryAction: (_) => action(),
    );
  }
}

class EnumEditor<T extends Enum> extends StatefulWidget {
  final int maxlength;
  final T selectedValue;
  final List<(T value, IconData icon, String label)> options;
  final void Function(T) onChanged;

  const EnumEditor({
    super.key,
    required this.selectedValue,
    this.maxlength = 4,
    required this.onChanged,
    required this.options,
  });

  @override
  State<EnumEditor<T>> createState() => _EnumEditorState<T>();
}

class _EnumEditorState<T extends Enum> extends State<EnumEditor<T>> {
  @override
  Widget build(BuildContext context) {
    bool overflow = widget.options.length > widget.maxlength;
    int length = overflow ? widget.maxlength : widget.options.length;

    return FloatingBar(
      decoration: FloatingBarDecoration.flatLightMode,
      children: [
        for (int i = 0; i < length; i++) ...[
          if (i != 0) SizedBox(height: 24, child: MyDividers.lightVertical),
          Expanded(
            child: optionButton(i),
          ),
          if (overflow && i == length - 1) ...[
            SizedBox(height: 24, child: MyDividers.lightVertical),
            MyIconButton(
              icon: LucideIcons.ellipsis,
              size: 20,
              tooltip: "More options",
              decoration: MyIconButtonDecoration.onDarkBar8.copyWith(
                  iconColor: InteractiveColorSettings(
                color: MyColors.storm,
                hoverColor: MyColors.light,
              )),
              primaryAction: (details) {
                ContextPopup.open(
                  context,
                  preferAlignment: Alignment.topRight,
                  clickPosition: details.globalPosition,
                  child: FloatingBar(
                    direction: Axis.vertical,
                    decoration: FloatingBarDecoration.flatLightMode,
                    children: [
                      for (int j = length; j < widget.options.length; j++)
                        optionButton(j, fromPopup: true),
                    ],
                  ),
                );
              },
            ),
          ]
        ]
      ],
    );
  }

  Widget optionButton(int index, {bool fromPopup = false}) {
    final option = widget.options[index];
    return MyIconButton(
      icon: option.$2,
      size: 20,
      tooltip: option.$3,
      isSelected: option.$1 == widget.selectedValue,
      decoration: MyIconButtonDecoration.onDarkBar8,
      primaryAction: (_) {
        widget.onChanged(option.$1);
        if (fromPopup) ContextPopup.close();
      },
    );
  }
}

extension EnumValues<T extends Enum> on Type {
  List<T> get values => (T.values as List<T>);
}
