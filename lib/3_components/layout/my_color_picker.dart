import 'package:flutter/material.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/click_detector.dart';
import 'package:jouhakka_forge/3_components/layout/context_popup.dart';
import 'package:jouhakka_forge/3_components/layout/gap.dart';
import 'package:jouhakka_forge/3_components/text_field.dart';
import 'package:jouhakka_forge/5_style/colors.dart';
import 'package:jouhakka_forge/5_style/textstyles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MyColorPicker extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;
  final Color initialColor;

  const MyColorPicker({
    required this.onColorChanged,
    required this.initialColor,
    super.key,
  });

  @override
  State<MyColorPicker> createState() => _MyColorPickerState();
}

enum _ColorEditMode { hex, rgba }

class _MyColorPickerState extends State<MyColorPicker> {
  late HSVColor hsvColor;
  late double opacity;
  static const double _sizePx = 280;
  static const Size _size = Size(_sizePx, _sizePx);

  _ColorEditMode _colorEditMode = _ColorEditMode.hex;

  @override
  void initState() {
    super.initState();
    hsvColor = HSVColor.fromColor(widget.initialColor);
    opacity = widget.initialColor.a;
  }

  void _updateColor(Offset position, Size size) {
    double saturation = (position.dx / size.width).clamp(0.0, 1.0);
    double value = 1 - (position.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      hsvColor = HSVColor.fromAHSV(1.0, hsvColor.hue, saturation, value);
    });
    widget.onColorChanged(hsvColor.toColor().withValues(alpha: opacity));
  }

  void _updateHue(double hue) {
    setState(() {
      hsvColor =
          HSVColor.fromAHSV(1.0, hue, hsvColor.saturation, hsvColor.value);
    });
    widget.onColorChanged(hsvColor.toColor().withValues(alpha: opacity));
  }

  void _updateOpacity(double newOpacity) {
    setState(() {
      opacity = newOpacity;
    });
    widget.onColorChanged(hsvColor.toColor().withValues(alpha: opacity));
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.light,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: MyColors.dark.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        width: _sizePx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    const Text(
                      'Color:',
                      style: MyTextStyles.darkHeader3,
                    ),
                    const Spacer(),
                    MyIconButton(
                      icon: LucideIcons.x,
                      size: 18,
                      primaryAction: (_) {
                        widget.onColorChanged(widget.initialColor);
                        ContextPopup.close();
                      },
                    ),
                    Gap.w4,
                    MyIconButton(
                      icon: LucideIcons.check,
                      size: 18,
                      decoration: const MyIconButtonDecoration(
                          iconColor: InteractiveColorSettings(
                              color: MyColors.darkMint)),
                      primaryAction: (_) {
                        ContextPopup.close();
                      },
                    ),
                  ],
                )),
            GestureDetector(
              onPanUpdate: (details) =>
                  _updateColor(details.localPosition, _size),
              onTapDown: (details) =>
                  _updateColor(details.localPosition, _size),
              child: CustomPaint(
                size: _size,
                painter: _ColorPickerPainter(hsvColor: hsvColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HueSlider(hue: hsvColor.hue, onChanged: _updateHue),
                  Gap.h12,
                  _OpacitySlider(
                    opacity: opacity,
                    color: hsvColor,
                    onChanged: _updateOpacity,
                  ),
                  Gap.h12,
                  Row(
                    children: [
                      ClickDetector(
                        primaryActionDown: (_) {
                          var newMode = _colorEditMode == _ColorEditMode.hex
                              ? _ColorEditMode.rgba
                              : _ColorEditMode.hex;
                          setState(() {
                            _colorEditMode = newMode;
                          });
                        },
                        builder: (hovering, pressed) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: hovering
                                  ? MyColors.storm12
                                  : Colors.transparent,
                              border: Border.all(
                                color: MyColors.storm30,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _colorEditMode == _ColorEditMode.hex
                                  ? 'HEX'
                                  : 'RGBA',
                              style: MyTextStyles.smallTip,
                            ),
                          );
                        },
                      ),
                      Gap.w4,
                      if (_colorEditMode == _ColorEditMode.hex) _hexEditor(),
                      if (_colorEditMode == _ColorEditMode.rgba) _rgbaEditor(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hexEditor() {
    return Expanded(
      child: MyTextField(
        controller: TextEditingController(
          text: '#${hsvColor.toColor().toHex()}',
        ),
        onChanged: (value) {
          if (value.length == 9) {
            try {
              final color = Color(
                int.parse(value.substring(1), radix: 16),
              );
              setState(() {
                hsvColor = HSVColor.fromColor(color);
                opacity = color.a;
              });
              widget.onColorChanged(color);
              return true;
            } catch (e) {
              return false;
            }
          } else {
            return false;
          }
        },
      ),
    );
  }

  Widget _rgbaEditor() {
    return Expanded(
      child: Row(
        children: [
          _rgbaTextField(
            label: 'R',
            value: hsvColor.toColor().r,
            onChanged: (value) => _updateRGBA(value, 'red'),
          ),
          Gap.w4,
          _rgbaTextField(
            label: 'G',
            value: hsvColor.toColor().g,
            onChanged: (value) => _updateRGBA(value, 'green'),
          ),
          Gap.w4,
          _rgbaTextField(
            label: 'B',
            value: hsvColor.toColor().b,
            onChanged: (value) => _updateRGBA(value, 'blue'),
          ),
          Gap.w4,
          _rgbaTextField(
            label: 'A',
            value: opacity,
            onChanged: (value) => _updateRGBA(value, 'opacity'),
          ),
        ],
      ),
    );
  }

  Widget _rgbaTextField({
    required String label,
    required double value,
    required bool Function(String) onChanged,
  }) {
    return Expanded(
      child: MyTextField(
        controller: TextEditingController(text: (value * 255).toString()),
        hint: TextFieldHint(HintType.background, text: label),
        onSubmitted: onChanged,
      ),
    );
  }

  bool _updateRGBA(String value, String channel) {
    try {
      final color = hsvColor.toColor();
      double red = color.r;
      double green = color.g;
      double blue = color.b;
      double alpha = opacity;

      switch (channel) {
        case 'red':
          red = double.parse(value) / 255;
          break;
        case 'green':
          green = double.parse(value) / 255;
          break;
        case 'blue':
          blue = double.parse(value) / 255;
          break;
        case 'opacity':
          alpha = double.parse(value) / 255;
          break;
      }

      final newColor =
          Color.from(red: red, green: green, blue: blue, alpha: alpha);
      setState(() {
        hsvColor = HSVColor.fromColor(newColor);
        opacity = newColor.a;
      });
      widget.onColorChanged(newColor);
      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }
}

class _ColorPickerPainter extends CustomPainter {
  final HSVColor hsvColor;

  _ColorPickerPainter({required this.hsvColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.black],
    );
    final Gradient gradientH = LinearGradient(
      colors: [
        Colors.white,
        HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = gradientH.createShader(rect),
    );

    final Paint thumbpaint = Paint()
      ..color = HSVColor.fromAHSV(
              1.0, hsvColor.hue, hsvColor.saturation, hsvColor.value)
          .toColor()
      ..style = PaintingStyle.fill;

    const double thumbSize = 20.0;
    final Offset thumbCenter = Offset(
      hsvColor.saturation * size.width,
      (1 - hsvColor.value) * size.height,
    );
    final Rect thumbRect = Rect.fromCenter(
        center: thumbCenter, width: thumbSize, height: thumbSize);
    final RRect thumbRRect =
        RRect.fromRectAndRadius(thumbRect, const Radius.circular(8));

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      thumbRRect.inflate(4), // Offset for shadow
      shadowPaint,
    );

    canvas.drawRRect(thumbRRect, thumbpaint);

    final Paint borderPaint = Paint()
      ..color = MyColors.light
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(thumbRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: List.generate(
            360,
            (index) =>
                HSVColor.fromAHSV(1.0, index.toDouble(), 1.0, 1.0).toColor(),
          ),
          stops: List.generate(360, (index) => index / 360),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: _CustomThumbShape(),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          min: 0,
          max: 360,
          value: hue,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          thumbColor: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
          activeColor: Colors.transparent,
          inactiveColor: Colors.transparent,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CustomThumbShape extends RoundSliderThumbShape {
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    final Rect thumbRect = Rect.fromCenter(
      center: center,
      width: 20,
      height: 24,
    );

    final RRect thumbRRect =
        RRect.fromRectAndRadius(thumbRect, const Radius.circular(8));

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      thumbRRect.inflate(4), // Offset for shadow
      shadowPaint,
    );

    canvas.drawRRect(thumbRRect, paint);

    final Paint borderPaint = Paint()
      ..color = MyColors.light
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(thumbRRect, borderPaint);
  }
}

class _OpacitySlider extends StatelessWidget {
  final double opacity;
  final HSVColor color;
  final ValueChanged<double> onChanged;

  const _OpacitySlider(
      {required this.opacity, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _CheckersPainter(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(
                            0.0, color.hue, color.saturation, color.value)
                        .toColor(),
                    HSVColor.fromAHSV(
                            1.0, color.hue, color.saturation, color.value)
                        .toColor(),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: _CustomThumbShape(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: 1,
              value: opacity,
              thumbColor: color.toColor().withValues(alpha: opacity),
              activeColor: Colors.transparent,
              inactiveColor: Colors.transparent,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double checkerSize = 8.0;
    final Paint lightPaint = Paint()..color = Colors.white;
    final Paint darkPaint = Paint()..color = Colors.grey;

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final Paint paint =
            ((x / checkerSize).floor() % 2 == (y / checkerSize).floor() % 2)
                ? lightPaint
                : darkPaint;
        canvas.drawRect(Rect.fromLTWH(x, y, checkerSize, checkerSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
