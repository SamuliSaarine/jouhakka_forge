import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/actions.dart';
import 'package:jouhakka_forge/2_services/template_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jouhakka_forge/2_services/session.dart' as s;

class AIService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> generateDesign(String prompt) async {
    final response = await _supabase.functions.invoke(
      'generate',
      body: {'prompt': prompt},
    );
    if (response.status != 200) {
      debugPrint(
          'Response did not succeed: ${response.status}: ${response.data}');
      throw Exception('Failed to: ${response.status}');
    }
    debugPrint('Generate design response: ${response.data}');
    final data = (response.data as Map).cast<String, dynamic>();
    /*ActionService.actionsFromList(
        (data['actions']! as List).cast<Map<String, dynamic>>());*/
    ElementRoot currentRoot = s.Session.lastPage.value!;
    UIElement? template = TemplateService.fromTemplate(
        data['template'], data['style'], currentRoot);
    if (template != null) {
      currentRoot.body = template;
    }
    return data;
  }

  /// Generates UI design actions based on the given prompt using Supabase Edge Function
  static Stream<Map<String, dynamic>> editDesignStream(String prompt) async* {
    try {
      debugPrint('Invoking generate function...');
      final response = await _supabase.functions.invoke(
        'edit',
        body: {'prompt': prompt},
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
      );

      debugPrint('Response status: ${response.status}');

      if (response.status != 200) {
        debugPrint('Error response data: ${response.data}');
        throw Exception('Failed to generate design: ${response.data}');
      }

      debugPrint('Processing stream data...');
      final stream = response.data as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer += text;

        // Process complete SSE messages
        final messages = buffer.split('\n\n');
        buffer =
            messages.last; // Keep the last incomplete message in the buffer

        for (final message in messages.sublist(0, messages.length - 1)) {
          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6);
            try {
              final data = jsonDecode(jsonStr);
              if (data['error'] != null) {
                throw Exception(data['error']);
              }
              yield data;
            } catch (e, s) {
              debugPrint('Error parsing chunk: $e');
              debugPrint('Stack trace: $s');
              debugPrint('Problematic JSON: $jsonStr');
            }
          }
        }
      }
    } catch (e, s) {
      debugPrint('Error generating design: $e\n$s');
      rethrow;
    }
  }

  /// Generates design actions and returns them as a complete list
  static Future<List<Map<String, dynamic>>> editDesign(String prompt,
      {void Function(Map<String, dynamic>)? onAction}) async {
    final actions = <Map<String, dynamic>>[];
    try {
      await for (final action in editDesignStream(prompt)) {
        actions.add(action);
        ActionService.singleAction(action);
        onAction?.call(action);
      }
      return actions;
    } catch (e) {
      debugPrint('Error in generateDesign: $e');
      rethrow;
    }
  }

  /// Extends a prompt with additional context for better UI design generation
  static Stream<String> extendPromptStream(String originalPrompt) async* {
    try {
      debugPrint('Invoking extend function...');
      final response = await _supabase.functions.invoke(
        'extend',
        body: {'original': originalPrompt},
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Response status: ${response.status}');

      if (response.status != 200) {
        debugPrint('Error response data: ${response.data}');
        throw Exception('Failed to extend prompt: ${response.data}');
      }

      debugPrint('Processing stream data...');
      final stream = response.data as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer += text;

        // Process complete SSE messages
        final messages = buffer.split('\n\n');
        buffer =
            messages.last; // Keep the last incomplete message in the buffer

        for (final message in messages.sublist(0, messages.length - 1)) {
          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6);
            try {
              final data = jsonDecode(jsonStr);

              if (data['error'] != null) {
                throw Exception(data['error']);
              }
              if (data['text'] != null) {
                yield data['text'] as String;
              }
            } catch (e) {
              debugPrint('Error parsing chunk: $e');
              debugPrint('Problematic JSON: $jsonStr');
            }
          }
        }
      }
    } catch (e, s) {
      debugPrint('Error extending prompt: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Extends a prompt and returns the complete result
  static Future<String> extendPrompt(String originalPrompt,
      {void Function(String)? onChunk}) async {
    final buffer = StringBuffer();
    try {
      await for (final chunk in extendPromptStream(originalPrompt)) {
        buffer.write(chunk);
        onChunk?.call(chunk);
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('Error in extendPrompt: $e');
      rethrow;
    }
  }
}
