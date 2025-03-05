import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/buttons/my_text_button.dart';
import 'package:jouhakka_forge/3_components/layout/floating_bar.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/state_management/change_listener.dart';
import 'package:jouhakka_forge/3_components/state_management/value_listener.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/icons/lucide_map.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

extension ColorEditor on Color {
  Widget getEditor(void Function(Color color) set) {
    return ColorPicker(
      colorPickerWidth: 200,
      pickerColor: this,
      onColorChanged: (color) {
        set(color);
      },
      displayThumbColor: true,
      hexInputBar: true,
      portraitOnly: true,
    );
  }
}

extension EVEditor<T> on EV<T> {
  Widget getEditor() {
    if (T == Color) {
      return (value as Color).getEditor((color) {
        setConstantValue(color as T);
      });
    } else if (T == double) {
      final TextEditingController valueController =
          TextEditingController(text: value.toString());
      return MyNumberField<double>(
        controller: valueController,
        hintText: "Value",
        onChanged: (value) {
          setConstantValue(value as T);
        },
      );
    }
    return const Text("Unsupported type");
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
              color: MyColors.lighterCharcoal,
              selectedColor: MyColors.mint,
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
        color: MyColors.darkerCharcoal,
        border: Border.all(color: MyColors.lighterCharcoal),
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

extension AxisSizeEditor on AxisSize {
  Widget getEditor(String title) {
    final TextEditingController valueController =
        TextEditingController(text: value != null ? value!.toString() : "");
    final TextEditingController minController = TextEditingController(
        text: minPixels != null ? minPixels!.toString() : "");
    final TextEditingController maxController = TextEditingController(
        text: maxPixels != null ? maxPixels!.toString() : "");
    final TextEditingController flexController =
        TextEditingController(text: flex != null ? flex!.toString() : "");

    return ChangeListener(
      source: this,
      builder: () {
        if (valueController.text != value.toString()) {
          valueController.text = value.toString();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title:",
                style: const TextStyle(
                    fontSize: 12,
                    color: MyColors.lighterCharcoal,
                    fontWeight: FontWeight.w700)),
            Gap.h2,
            Row(
              children: [
                Expanded(
                  child: MyNumberField<double>(
                      controller: valueController,
                      hintText: "$title in pixels",
                      onChanged: (value) => fixed(value)),
                ),
                Gap.w8,
                //MyIconButtons for auto, expand, fixed
                FloatingBar(
                  decoration: FloatingBarDecoration.flatLightMode,
                  children: [
                    MyIconButton(
                        icon: LucideIcons.shrink,
                        tooltip: "Auto",
                        size: 14,
                        isSelected: type == SizeType.auto,
                        decoration: MyIconButtonDecoration.onDarkBar8,
                        primaryAction: (_) {
                          auto();
                        }),
                    MyIconButton(
                        icon: LucideIcons.expand,
                        tooltip: "Expand",
                        size: 14,
                        isSelected: type == SizeType.expand,
                        decoration: MyIconButtonDecoration.onDarkBar8,
                        primaryAction: (_) {
                          expand();
                        }),
                    MyIconButton(
                      icon: LucideIcons.ruler,
                      tooltip: "Fixed",
                      size: 14,
                      isSelected: type == SizeType.fixed,
                      decoration: MyIconButtonDecoration.onDarkBar8,
                      primaryAction: (_) {
                        if (value != null) {
                          fixed(value!);
                        } else {
                          debugPrint("Value is null");
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            //Min, max and if expand, flex
            if (type != SizeType.fixed) ...[
              Gap.h8,
              Row(
                children: [
                  Expanded(
                    child: MyNumberField<double>(
                      controller: minController,
                      hintText: "Min",
                      onChanged: (value) {
                        minPixels = value;
                      },
                    ),
                  ),
                  Gap.w4,
                  Expanded(
                    child: MyNumberField<double>(
                      controller: maxController,
                      hintText: "Max",
                      onChanged: (value) {
                        maxPixels = value;
                      },
                    ),
                  ),
                  if (type == SizeType.expand) ...[
                    Gap.w4,
                    Expanded(
                      child: MyNumberField<int>(
                        controller: flexController,
                        hintText: "Flex",
                        onChanged: (value) {
                          flex = value;
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}

extension ContainerElementEditor on ElementContainerType {
  Widget getEditor({required void Function(Axis axis) onScrollEnable}) {
    return ChangeListener(
        source: this,
        builder: () {
          return Column(
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

extension TextElementEditor on TextElement {
  Widget getEditor() {
    final TextEditingController textController =
        TextEditingController(text: text);
    final TextEditingController fontSizeController =
        TextEditingController(text: fontSize.toString());

    return ChangeListener(
      source: this,
      builder: () {
        return Column(
          children: [
            MyTextField(
              controller: textController,
              hintText: "Text",
              onChanged: (value) {
                text = value;
              },
            ),
            Gap.h8,
            MyNumberField<double>(
              controller: fontSizeController,
              hintText: "Font size",
              onChanged: (value) {
                fontSize = value;
              },
            ),
            alignment.getEditor((alignment) {
              this.alignment = alignment;
            }),
          ],
        );
      },
    );
  }
}

extension IconElementEditor on IconElement {
  Widget getEditor() {
    return ChangeListener(
      source: this,
      builder: () {
        return SizedBox(
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // Adjust this to fit your layout needs
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: lucideMap.length,
            itemBuilder: (context, index) {
              (String, int) item = lucideMap[index];
              IconData iconData = IconData(
                item.$2,
                fontFamily: 'Lucide',
                fontPackage: 'lucide_icons_flutter',
              );
              return MyIconButton(
                icon: iconData,
                tooltip: item.$1,
                decoration: const MyIconButtonDecoration(
                  iconColor: InteractiveColorSettings(color: Colors.black),
                  backgroundColor: InteractiveColorSettings(
                    color: Colors.white,
                    hoverColor: Color.fromARGB(255, 210, 210, 210),
                    selectedColor: Color.fromARGB(255, 107, 107, 107),
                  ),
                  borderRadius: 12,
                ),
                isSelected: icon == iconData,
                primaryAction: (_) {
                  icon = iconData;
                },
              );
            },
          ),
        );
      },
    );
  }
}

extension OptionalPropertyEditor<T> on OptionalProperty<T> {
  Widget getEditor() {
    if (T == EdgeInsets) {
      EdgeInsets initialPadding =
          value is EdgeInsets ? value as EdgeInsets : EdgeInsets.zero;
      return initialPadding.getEditor(
        "Padding",
        (padding) {
          value = padding as T;
        },
      );
    } else if (T == ElementDecoration) {
      return ValueListener(
        source: hasValueNotifier,
        builder: (hasValue) {
          if (hasValue) {
            return Column(
              children: [
                (value as ElementDecoration).getEditor(),
                Center(
                  child: MyTextButton(
                    text: "Delete decoration",
                    size: 12,
                    decoration: const MyTextButtonDecoration(
                      textColor: InteractiveColorSettings(color: Colors.red),
                      borderRadius: 8,
                    ),
                    primaryAction: (_) {
                      value = null;
                      hasValueNotifier.value = false;
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: MyTextButton(
                text: "+ Decoration",
                size: 16,
                primaryAction: (_) {
                  value = ElementDecoration() as T;
                  hasValueNotifier.value = true;
                },
              ),
            );
          }
        },
      );
    }
    return const Text("Unsupported type");
  }
}

extension EdgeInsetsEditor on EdgeInsets {
  Widget getEditor(String title, Function(EdgeInsets padding) set) {
    final TextEditingController topController =
        TextEditingController(text: top.toString());
    final TextEditingController leftController =
        TextEditingController(text: left.toString());
    final TextEditingController rightController =
        TextEditingController(text: right.toString());
    final TextEditingController bottomController =
        TextEditingController(text: bottom.toString());

    bool topSelected = false;
    bool leftSelected = false;
    bool rightSelected = false;
    bool bottomSelected = false;

    void setPadding(double value,
        {bool fromTop = false,
        bool fromLeft = false,
        bool fromRight = false,
        bool fromBottom = false}) {
      if (!fromTop && topSelected) {
        topController.text = value.toString();
      }
      if (!fromLeft && leftSelected) {
        leftController.text = value.toString();
      }
      if (!fromRight && rightSelected) {
        rightController.text =
            rightSelected ? value.toString() : right.toString();
      }
      if (!fromBottom && bottomSelected) {
        bottomController.text =
            bottomSelected ? value.toString() : bottom.toString();
      }
      set(
        EdgeInsets.only(
          top: topSelected ? value : double.tryParse(topController.text) ?? 0,
          left:
              leftSelected ? value : double.tryParse(leftController.text) ?? 0,
          right: rightSelected
              ? value
              : double.tryParse(rightController.text) ?? 0,
          bottom: bottomSelected
              ? value
              : double.tryParse(bottomController.text) ?? 0,
        ),
      );
    }

    void selectFields(
        {bool top = false,
        bool left = false,
        bool right = false,
        bool bottom = false}) {
      topSelected = top;
      leftSelected = left;
      rightSelected = right;
      bottomSelected = bottom;
    }

    void handleSelection(
        {bool top = false,
        bool left = false,
        bool right = false,
        bool bottom = false}) {
      assert(top ^ left ^ right ^ bottom, "One field must be selected");
      if (HardwareKeyboard.instance.isShiftPressed) {
        selectFields(top: true, left: true, right: true, bottom: true);
      } else if (HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed) {
        if (top || bottom) {
          selectFields(top: true, bottom: true);
        } else if (left || right) {
          selectFields(left: true, right: true);
        }
      } else {
        selectFields(top: top, left: left, right: right, bottom: bottom);
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title:",
                style: const TextStyle(
                    fontSize: 12,
                    color: MyColors.lighterCharcoal,
                    fontWeight: FontWeight.w700)),
            Gap.h2,
            Row(
              children: [
                Expanded(
                  child: MyNumberField<double>(
                    onTap: () {
                      handleSelection(top: true);
                      setState(() {});
                      debugPrint("Top selected: $topSelected");
                    },
                    isSelectedOverride: topSelected,
                    controller: topController,
                    hintText: "Top",
                    onChanged: (value) => setPadding(value, fromTop: true),
                    onSubmitted: () {
                      selectFields();
                      setState(() {});
                    },
                  ),
                ),
                Gap.w4,
                Expanded(
                  child: MyNumberField<double>(
                    onTap: () {
                      handleSelection(left: true);
                      setState(() {});
                    },
                    isSelectedOverride: leftSelected,
                    controller: leftController,
                    hintText: "Left",
                    onChanged: (value) => setPadding(value, fromLeft: true),
                    onSubmitted: () {
                      selectFields();
                      setState(() {});
                    },
                  ),
                ),
                Gap.w4,
                Expanded(
                  child: MyNumberField<double>(
                    onTap: () {
                      handleSelection(right: true);
                      setState(() {});
                    },
                    isSelectedOverride: rightSelected,
                    controller: rightController,
                    hintText: "Right",
                    onChanged: (value) => setPadding(value, fromRight: true),
                    onSubmitted: () {
                      selectFields();
                      setState(() {});
                    },
                  ),
                ),
                Gap.w4,
                Expanded(
                  child: MyNumberField<double>(
                    onTap: () {
                      handleSelection(bottom: true);
                      setState(() {});
                    },
                    isSelectedOverride: bottomSelected,
                    controller: bottomController,
                    hintText: "Bottom",
                    onChanged: (value) => setPadding(value, fromBottom: true),
                    onSubmitted: () {
                      selectFields();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

extension ElementDecorationEditor on ElementDecoration {
  Widget getEditor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        backgroundColor.getEditor(),
        Gap.h8,
        radius.getEditor(),
        Gap.h8,
        borderWidth.getEditor(),
        Gap.h8,
        borderColor.getEditor(),
        Gap.h8,
        margin.getEditor(),
      ],
    );
  }
}

extension ElementContainerEditor on ElementContainer {
  Widget getEditor() {
    return Column(
      children: [
        padding.getEditor("Padding", (padding) {
          this.padding = padding;
        }),
      ],
    );
  }
}
