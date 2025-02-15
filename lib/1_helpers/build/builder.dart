import 'package:build/build.dart';
import 'package:jouhakka_forge/1_helpers/build/generators.dart';
import 'package:source_gen/source_gen.dart';

Builder notifierBuilder(BuilderOptions options) => SharedPartBuilder(
      [NotifierGenerator()],
      'notifier',
    );
