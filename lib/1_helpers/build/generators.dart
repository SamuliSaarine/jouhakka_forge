import 'package:analyzer/dart/element/element.dart';
import 'package:jouhakka_forge/1_helpers/build/annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

class NotifierGenerator extends GeneratorForAnnotation<Notifier> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@notifier` can only be applied to classes.',
        element: element,
      );
    }

    final notifyFields = element.fields.where((field) {
      return field.metadata.any((meta) =>
          meta.element?.name == 'notify' ||
          meta.element?.name == 'notifyAndForward');
    });

    if (notifyFields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields annotated with `@notify` found.',
        element: element,
      );
    }

    final buffer = StringBuffer();

    buffer.writeln(
        'extension ${element.name}NotifyExtension on ${element.name} {');

    for (final field in notifyFields) {
      bool forwardListener = field.metadata
          .any((meta) => meta.element?.name == 'notifyAndForward');
      buffer.writeln(_generateNotifyFieldCode(field, forwardListener));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateNotifyFieldCode(FieldElement field, bool forwardListener) {
    final fieldName = field.name;
    final publicName =
        fieldName.startsWith('_') ? fieldName.substring(1) : fieldName;
    final fieldType = field.type.getDisplayString();

    return '''
      $fieldType get $publicName => $fieldName;
      set $publicName($fieldType value) {
        if ($fieldName == value) return;
        $fieldName = value;
        ${forwardListener ? 'if(value is ChangeNotifier){($fieldName as ChangeNotifier).addListener(notifyListeners)}' : ''}
        notifyListeners();
      }
    ''';
  }
}

class DesignModelGenerator extends GeneratorForAnnotation<DesignModel> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@designModel` can only be applied to classes.',
        element: element,
      );
    }

    final designFields = element.fields.where((field) {
      return field.metadata.any((meta) => meta.element?.name == 'DesignField');
    });

    final holderFields = element.fields.where((field) {
      return field.metadata
          .any((meta) => meta.element?.name == 'DesignFieldHolder');
    });

    if (designFields.isEmpty && holderFields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields annotated with `@DesignField` or `@DesignFieldHolder` found.',
        element: element,
      );
    }

    final buffer = StringBuffer();

    final description =
        annotation.objectValue.getField('description')?.toStringValue();
    buffer.writeln(
        'extension ${element.name}DesignModelExtension on ${element.name} {');

    buffer.writeln("static const designModel = '''{");
    buffer.writeln('''this: {
      "type": "${element.name}",
      "description": "$description",
    },''');
    for (final field in designFields) {
      buffer.writeln(_generateDesignModelFieldCode(field));
    }

    for (final field in holderFields) {
      final fieldTypeElement = field.type.element;
      if (fieldTypeElement is ClassElement) {
        final annotation = field.metadata
            .firstWhere((meta) => meta.element?.name == 'DesignFieldHolder')
            .computeConstantValue();
        final fields = annotation
                ?.getField('fields')
                ?.toListValue()
                ?.map((e) => e.toStringValue())
                .toList() ??
            [];
        for (final subField in fieldTypeElement.fields) {
          final subFieldPublicName = subField.name.startsWith('_')
              ? subField.name.substring(1)
              : subField.name;
          if (fields.contains(subFieldPublicName)) {
            buffer.writeln(_generateDesignModelFieldCode(subField));
          }
        }
      }
    }

    buffer.writeln("}''';");
    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateDesignModelFieldCode(FieldElement field) {
    final fieldName = field.name;
    final fieldType = field.type.getDisplayString();
    final annotation = field.metadata
        .firstWhere((meta) => meta.element?.name == 'DesignField')
        .computeConstantValue();
    final description = annotation?.getField('description')?.toStringValue();
    final valueRestrictions =
        annotation?.getField('valueRestrictions')?.toStringValue();
    final defaultValue = annotation?.getField('defaultValue')?.toStringValue();
    final isRequired = annotation?.getField('isRequired')?.toBoolValue();

    return ('''
        $fieldName: {
          "type": "$fieldType",
          "description": "$description",
          "valueRestrictions": "$valueRestrictions",  
          "defaultValue": "$defaultValue",
          "isRequired": $isRequired,
        },
      }''');
  }
}
