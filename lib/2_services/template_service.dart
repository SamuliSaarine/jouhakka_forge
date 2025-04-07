import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/container_element.dart';
import 'package:jouhakka_forge/0_models/elements/element_utility.dart';
import 'package:jouhakka_forge/0_models/elements/media_elements.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/0_models/variable_map.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';
import 'package:jouhakka_forge/1_helpers/extensions.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/element/container_editor.dart';
import 'package:jouhakka_forge/3_components/element/picker/element_picker.dart';

class TemplateService {
  static UIElement? fromTemplate(
    Map<String, dynamic> templateMap,
    Map<String, dynamic> style,
    ElementRoot root,
  ) {
    bool variablesSet = variablesFromStyle(style);
    if (!variablesSet) {
      return null;
    }

    try {
      final template = LandingTemplate.fromJson(templateMap);
      return template.build(root, style);
    } catch (e) {
      debugPrint('Error building template: $e');
      return null;
    }
  }

  static bool variablesFromStyle(Map<String, dynamic> style) {
    try {
      VariableMap variables = Session.currentProject.value!.variables;

      Color backgroundColor =
          ColorExtension.fromHex(style['colors']['background']);
      variables.setValue("background", backgroundColor);
      Color textColor = ColorExtension.fromHex(style['colors']['text']);
      variables.setValue("textColor", textColor);
      Color surface = ColorExtension.fromHex(style['colors']['surface']);
      variables.setValue("surface", surface);
      Color accent = ColorExtension.fromHex(style['colors']['accent']);
      variables.setValue<Color>("accent", accent);

      String titleSize = style['textStyles']['title']['fontSize'];
      variables.setValue<double>(
        "titleSize",
        titleSize == "m"
            ? 40
            : titleSize == "l"
                ? 56
                : 72,
      );
      variables.setValue<String>(
        "titleWeight",
        style['textStyles']['title']['fontWeight'],
      );

      String bodySize = style['textStyles']['body']['fontSize'];
      variables.setValue<double>(
        "bodyTextSize",
        bodySize == "s"
            ? 16
            : bodySize == "m"
                ? 18
                : 20,
      );
      variables.setValue<String>(
        "bodyTextWeight",
        style['textStyles']['body']['fontWeight'],
      );

      String linkSize = style['textStyles']['link']['fontSize'];
      variables.setValue<double>(
        "linkSize",
        linkSize == "s"
            ? 18
            : linkSize == "m"
                ? 20
                : 22,
      );
      variables.setValue<String>(
        "linkWeight",
        style['textStyles']['link']['fontWeight'],
      );

      String buttonRadius = style['buttonStyles']['radius'];

      variables.setValue<double>(
        "buttonRadius",
        buttonRadius == 'none'
            ? 0
            : buttonRadius == 'small'
                ? 8
                : buttonRadius == 'medium'
                    ? 12
                    : buttonRadius == 'large'
                        ? 16
                        : 24,
      );

      return true;
    } catch (e) {
      debugPrint("Error setting variables from style: $e");
      return false;
    }
  }
}

extension _ElementHelper on UIElement {
  void setHeight(double height) {
    size.height = ControlledSize.constant(height);
  }

  void setWidth(double width) {
    size.width = ControlledSize.constant(width);
  }
}

extension _BranchHelper on BranchElement {
  BranchElement addEmptyBelow() => addChildFromType(
        UIElementType.empty,
        AddDirection.bottom,
      ) as BranchElement;

  BranchElement addEmptyRight() => addChildFromType(
        UIElementType.empty,
        AddDirection.right,
      ) as BranchElement;

  void filledDecoration({required String colorKey, String? radiusKey}) {
    decoration.value ??= ElementDecoration();
    ElementDecoration deco = decoration.value!;
    deco.backgroundColor.change(
        (notifyListeners) => GlobalVariable<Color>(colorKey, notifyListeners));
    if (radiusKey != null) {
      decoration.value!.radius = MyRadius.all(
        GlobalVariable<double>(radiusKey, deco.notifyListeners),
      );
    }
  }

  void borderDecoration({required String colorKey, required String radiusKey}) {
    decoration.value ??= ElementDecoration();
    ElementDecoration deco = decoration.value!;
    deco.border.value = MyBorder.all(
        GlobalVariable<Color>(colorKey, deco.notifyListeners),
        ConstantVariable(1.5));
    deco.radius = MyRadius.all(
      GlobalVariable<double>(radiusKey, deco.notifyListeners),
    );
  }

  BranchElement addButton(String text, bool isPrimary,
      {AddDirection direction = AddDirection.bottom}) {
    final button =
        addChildFromType(UIElementType.empty, direction) as BranchElement;
    final buttonText =
        button.addChildFromType(UIElementType.text, null) as TextElement;
    buttonText.setText(text, 'link');
    buttonText.size.width = ShrinkingSize();
    buttonText.size.height = ShrinkingSize();
    if (isPrimary) {
      button.filledDecoration(colorKey: 'accent', radiusKey: 'buttonRadius');
    } else {
      button.borderDecoration(colorKey: 'accent', radiusKey: 'buttonRadius');
    }
    button.size.width = ShrinkingSize();
    button.content.value!.padding = MyPadding.constant(8, 8, 12, 12);
    return button;
  }
}

abstract class Template {
  UIElement build(
    ElementRoot root,
    Map<String, dynamic> style,
  );
}

class LandingTemplate extends Template {
  final List<String> headerLinks;
  final MainAxisAlignment headerAlignment;
  final TextAlign contentAlignment;
  final String headerCTA;
  final String headerSecondaryCTA;
  final String landingTitle;
  final String landingDescription;
  final String landingCTA;
  final String landingSecondaryCTA;
  final String landingImage;
  final bool imageIsBackground;
  final List<String> footerLinks;
  final MainAxisAlignment footerAlignment;

  LandingTemplate._({
    required this.headerLinks,
    required this.headerAlignment,
    required this.contentAlignment,
    required this.headerCTA,
    required this.headerSecondaryCTA,
    required this.landingTitle,
    required this.landingDescription,
    required this.landingCTA,
    required this.landingSecondaryCTA,
    required this.landingImage,
    required this.footerLinks,
    required this.footerAlignment,
    required this.imageIsBackground,
  });

  factory LandingTemplate.fromJson(Map<String, dynamic> json) {
    MainAxisAlignment headerAlignment;
    switch (json['header']['linksAlignment']) {
      case 'right':
        headerAlignment = MainAxisAlignment.end;
        break;
      case 'center':
        headerAlignment = MainAxisAlignment.center;
        break;
      default:
        headerAlignment = MainAxisAlignment.start;
    }
    MainAxisAlignment footerAlignment;
    switch (json['footer']['linksAlignment']) {
      case 'right':
        footerAlignment = MainAxisAlignment.end;
        break;
      case 'center':
        footerAlignment = MainAxisAlignment.center;
        break;
      default:
        footerAlignment = MainAxisAlignment.start;
    }
    TextAlign contentAlignment;
    switch (json['body']['contentAlignment']) {
      case 'right':
        contentAlignment = TextAlign.right;
        break;
      case 'center':
        contentAlignment = TextAlign.center;
        break;
      default:
        contentAlignment = TextAlign.left;
    }
    return LandingTemplate._(
      landingTitle: json['body']?['title'] ?? '',
      headerAlignment: headerAlignment,
      landingDescription: json['body']?['paragraph'] ?? '',
      landingCTA: json['body']?['cta'] ?? '',
      landingSecondaryCTA: json['body']?['secondaryCTA'] ?? '',
      landingImage: json['body']?['image'] ?? '',
      imageIsBackground: json['body']?['imageIsBackground'] ?? false,
      headerLinks: json['header']?['links'] != null
          ? (json['header']?['links'] as List).cast<String>()
          : [],
      headerCTA: json['header']?['cta'] ?? '',
      headerSecondaryCTA: json['header']?['secondaryCTA'] ?? '',
      footerLinks: json['footer']?['links'] != null
          ? (json['footer']?['links'] as List).cast<String>()
          : [],
      footerAlignment: footerAlignment,
      contentAlignment: contentAlignment,
    );
  }

  @override
  UIElement build(ElementRoot root, Map<String, dynamic> style) {
    assert(root.body is BranchElement, 'Body must be a BranchElement');
    final body = root.body as BranchElement;
    body.filledDecoration(colorKey: 'background');
    final header = body.addEmptyBelow();
    final lander = body.addEmptyBelow();
    final footer = body.addEmptyBelow();
    header.setHeight(100);
    footer.setHeight(100);
    // Header
    final headerSpacer = header.addEmptyRight();
    header.content.value!.padding = MyPadding.constant(20, 20, 32, 32);
    if (headerLinks.isNotEmpty) {
      for (final link in headerLinks) {
        final linkElement = headerSpacer.addChildFromType(
            UIElementType.text, AddDirection.right) as TextElement;
        linkElement.setText(link, 'link');
        linkElement.size.width = ShrinkingSize();
      }
      final linkFlex = headerSpacer.content.value!.type as FlexElementType;
      linkFlex.mainAxisAlignment = headerAlignment;
      linkFlex.spacing = ConstantVariable(32);
    }
    if (headerSecondaryCTA.isNotEmpty) {
      header.addButton(headerSecondaryCTA, false,
          direction: AddDirection.right);
    }
    if (headerCTA.isNotEmpty) {
      header.addButton(headerCTA, true, direction: AddDirection.right);
    }
    if (headerSecondaryCTA.isNotEmpty || headerCTA.isNotEmpty) {
      final headerFlex = header.content.value!.type as FlexElementType;
      headerFlex.spacing = ConstantVariable(32);
    }

    // Lander
    bool hasImage = landingImage.isNotEmpty && !imageIsBackground;
    final landerContent = hasImage ? lander.addEmptyRight() : lander;
    if (landingTitle.isNotEmpty) {
      final title = landerContent.addChildFromType(
          UIElementType.text, AddDirection.bottom) as TextElement;
      title.setText(landingTitle, 'title');
      title.alignment = contentAlignment == TextAlign.left
          ? Alignment.centerLeft
          : contentAlignment == TextAlign.right
              ? Alignment.centerRight
              : Alignment.center;
      title.size.height = ShrinkingSize();
    }
    if (landingDescription.isNotEmpty) {
      final description = landerContent.addChildFromType(
          UIElementType.text, AddDirection.bottom) as TextElement;
      description.setText(landingDescription, 'bodyText');
      description.alignment = contentAlignment == TextAlign.left
          ? Alignment.centerLeft
          : contentAlignment == TextAlign.right
              ? Alignment.centerRight
              : Alignment.center;
      description.size.height = ShrinkingSize();
    }
    landerContent.content.value!.padding = MyPadding.constantAll(40);
    final spacer = landerContent.addEmptyBelow();
    spacer.setHeight(24);

    bool ctaRow = landingCTA.isNotEmpty && landingSecondaryCTA.isNotEmpty;
    final ctaContainer = ctaRow ? landerContent.addEmptyBelow() : landerContent;
    if (landingSecondaryCTA.isNotEmpty) {
      final button = ctaContainer.addButton(landingSecondaryCTA, false,
          direction: AddDirection.right);
      button.size.height = ShrinkingSize();
    }
    if (landingCTA.isNotEmpty) {
      final button = ctaContainer.addButton(landingCTA, true,
          direction: AddDirection.right);
      button.size.height = ShrinkingSize();
    }
    if (ctaRow) {
      final ctaFlex = ctaContainer.content.value!.type as FlexElementType;
      ctaFlex.spacing = ConstantVariable(32);
      ctaFlex.mainAxisAlignment = contentAlignment == TextAlign.left
          ? MainAxisAlignment.start
          : contentAlignment == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.center;
      ctaContainer.size.height = ShrinkingSize();
    }
    final contentFlex = landerContent.content.value!.type as FlexElementType;
    contentFlex.crossAxisAlignment = contentAlignment == TextAlign.left
        ? CrossAxisAlignment.start
        : contentAlignment == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center;
    contentFlex.mainAxisAlignment = MainAxisAlignment.center;

    if (hasImage) {
      final imageHolder = lander.addEmptyRight();
      imageHolder.addChildFromType(
        UIElementType.image,
        AddDirection.bottom,
      ) as ImageElement;
      imageHolder.content.value!.padding = MyPadding.constantAll(24);
    }

    // Footer
    if (footerLinks.isNotEmpty) {
      for (final link in footerLinks) {
        final linkElement = footer.addChildFromType(
            UIElementType.text, AddDirection.right) as TextElement;
        linkElement.setText(link, 'link');
        linkElement.size.width = ShrinkingSize();
      }
      final linkFlex = footer.content.value!.type as FlexElementType;
      linkFlex.mainAxisAlignment = footerAlignment;
      linkFlex.spacing = ConstantVariable(32);
    }

    return body;
  }
}

extension _TextElementHelper on TextElement {
  void setText(String text, String type) {
    this.text = ConstantVariable<String>(text);
    fontSize = GlobalVariable<double>("${type}Size", notifyListeners);
    fontWeight = FontWeightExtension.fromString(
      GlobalVariable<String>('${type}Weight', notifyListeners).value,
    );
    color = GlobalVariable('textColor', notifyListeners);
  }
}
