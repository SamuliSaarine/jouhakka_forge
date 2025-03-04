// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  // Check if a path was provided as a command-line argument
  if (arguments.isEmpty) {
    print('Please provide the path to the info.json file as an argument.');
    return;
  }

  // Get the path from the arguments
  String jsonFilePath = arguments[0];

  // Check if the file exists
  final File jsonFile = File(jsonFilePath);
  if (!jsonFile.existsSync()) {
    print('The file at $jsonFilePath does not exist.');
    return;
  }

  // Read the JSON file
  final String jsonString = await jsonFile.readAsString();
  final Map<String, dynamic> data = json.decode(jsonString);

  // Output file path
  final File outputFile = File('lucide_map.dart');
  final sink = outputFile.openWrite();

  // Write the Dart code into the output file
  sink.writeln("const List<(String, int)> lucideMap = [");

  // Iterate over the data and write the map entries
  data.forEach((key, value) {
    // Retrieve the encodedCode from the JSON structure
    String encodedCode = value["encodedCode"];

    // Ensure that the encodedCode starts with "\e" and process it correctly

    String hexCode = encodedCode.substring(1); // Remove the "\e"
    try {
      int codepoint = int.parse(hexCode, radix: 16); // Convert to integer
      // Write the icon entry to the Dart file with codepoint
      sink.writeln("  ('$key', $codepoint),");
    } catch (e) {
      print('Error parsing hex code for $key: $encodedCode');
    }
  });

  sink.writeln("];");

  // Close the file writer
  await sink.flush();
  await sink.close();

  print('lucideMap.dart has been generated at the current directory!');
}
