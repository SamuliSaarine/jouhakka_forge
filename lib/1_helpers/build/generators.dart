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
