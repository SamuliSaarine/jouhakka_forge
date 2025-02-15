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
      return field.metadata.any((meta) => meta.element?.name == 'notify');
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
      buffer.writeln(_generateNotifyFieldCode(field));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateNotifyFieldCode(FieldElement field) {
    final fieldName = field.name;
    final publicName =
        fieldName.startsWith('_') ? fieldName.substring(1) : fieldName;
    final fieldType = field.type.getDisplayString();

    return '''
      $fieldType get $publicName => $fieldName;
      set $publicName($fieldType value) {
        if ($fieldName == value) return;
        $fieldName = value;
        notifyListeners();
      }
    ''';
  }
}
