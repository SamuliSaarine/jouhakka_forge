import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIService {
  static final String _apiKey = Platform.environment['OPENAI_KEY_MUOTOI']!;

  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _responsesUrl = 'https://api.openai.com/v1/responses';

  static Future<String> extendPromt(String original,
      {void Function(String)? then}) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "developer", "content": extensionPromt},
            {"role": "user", "content": original}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint("Content as ${content.runtimeType}: $content");
        then?.call(content);
        return content;
      } else {
        throw Exception('Failed to fetch response: ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to extend promt");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> initialActions(
      String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "developer",
              "content": devPromtWithRules + _commandrules.toString()
            },
            {"role": "user", "content": prompt}
          ],
          "response_format": _commandschema,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        debugPrint("Content as ${content.runtimeType}: $content");
        return (jsonDecode(content)['actions'] as List)
            .cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch response: ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to get chat response: $e");
      rethrow;
    }
  }

  static Future<String> getFinalFormat(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "developer", "content": devPromtWithSchema},
            {"role": "user", "content": prompt}
          ],
          "response_format": actionschema //{"type": "json_object"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        debugPrint("Content as ${content.runtimeType}: $content");
        return content;
      } else {
        throw Exception('Failed to fetch response: ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to get chat response: $e");
      rethrow;
    }
  }

  static Future<String> editDesing(String design, String extended) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "developer", "content": editData},
            {"role": "assistant", "content": extended},
            {"role": "user", "content": design}
          ],
          "response_format": {"type": "json_object"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        debugPrint("Content as ${content.runtimeType}: $content");
        return content;
      } else {
        throw Exception('Failed to fetch response: ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to get chat response: $e");
      rethrow;
    }
  }

  static const String extensionPromt = '''
    You are a professional UI designer tasked with extending the given prompt to create a high-quality draft for a UI design. Your goal is to provide a creative, visually appealing, and user-friendly design foundation that serves as an excellent starting point for a human designer to refine. 

    Focus on the following principles:
    - **Clarity and Usability**: Ensure the design is intuitive and easy to navigate for users.
    - **Visual Appeal**: Use appropriate colors, spacing, and alignment to create an aesthetically pleasing layout.
    - **Responsiveness**: Assume the design should work seamlessly on both mobile and desktop platforms unless otherwise specified.

    Your output should consist of specific, actionable steps to build the design. For example, if the prompt is to create a landing page, your steps might include:
    1. Set the root element's background color to a visually suitable shade.
    2. Add two child elements to the root: 
       - The first child should serve as a header and contain a row of text elements.
       - The second child should be placed below the first and act as the main content area.
    3. In the header, add a row of text elements for the title and subtitle. Align them to the left.
    4. Add a button labeled "Get Started" to the right side of the header:
       - Create a branch element for the button with a background color and rounded corners.
       - Add a text element as a child of the button and adjust its padding to center the text.

    Remember, the example above is just a guideline. Your steps should be tailored to the specific prompt provided. Be precise and logical in your instructions, ensuring that the resulting design is well-structured and adheres to best practices for UI/UX design.
    ''';

  static const String devPromtWithRules = '''
    You are a professional UI designer tasked with creating a UI design based on the given prompt. Follow the steps below in the correct order to ensure a high-quality design:

1. **Understand the Design Requirements**: Carefully analyze the prompt to identify the required UI elements and their hierarchy.

2. **Follow the Target Path Rules**:
   - The design is represented as a tree structure where the root element is the starting point.
   - Use the target path to specify the position of each element in the hierarchy. For example:
     - `[]` refers to the root element.
     - `[0]` refers to the first child of the root element.
     - `[1, 2]` refers to the third child of the second child of the root element.
   - Ensure that all parent elements are created before adding child elements. For example, to edit `[1, 2]`, you must first create `[1]` and its children.

3. **Design with Precision**:
   - Clearly define the type of each UI element (e.g., button, text field, container).
   - Specify properties such as size, color, alignment, and padding for each element.
   - Ensure that the hierarchy and layout are consistent with the prompt.

4. **Validate the Design**:
   - Double-check that all elements are created in the correct order according to the target path.
   - Ensure that the design is visually appealing and adheres to best practices for UI/UX.

5. **Output the Design**:
   - Provide a clear and structured representation of the design, including the hierarchy and properties of each element.
   - Use comments or annotations to explain the purpose of each element and its position in the hierarchy.

Remember, your goal is to think and work like a real designer, ensuring that the design is both functional and aesthetically pleasing. Pay close attention to the hierarchy and the relationships between elements to create a cohesive and well-structured UI.
    
    Rules for available actions uses abbreviations explained below:
    - d: description
    - oa: optional arguments, if you want to keep the default value of argument, you leave the argument out of the arguments list.
    - ra: required arguments, you need to provide value for this argument in the arguments list.
    - t: type of argument, you can use this type to validate the value of the argument.
    - f: format of argument, you can use this format to validate the value of the argument.
    - v: default value of argument, you can use this to decide if you need to include the argument in the arguments list.
    - e: List of valid values for the enum type argument. You should not use other values than these for the argument. 
         For example "horizontal" is invalid for addChild direction argument, but "left" is valid.

    Available actions are:
    ''';

  static const Map<String, dynamic> rulesForActions = {
    "abstract elements": {
      "description": '''elements are inheriting from abstract elements. 
      You can't add them directly but addable elements are inheriting available properties from them, 
      so for example width and height are available for all elements. 
      Unless overridden, default values are inherited as well.''',
      "types": {
        "uielement": {
          "description": "Base element, where all elements are inheriting from",
          "availableProperties": ["width", "height"],
          "defaultValues": {
            "width": {"type": "expand", "min": 0, "max": double.infinity},
            "height": {"type": "expand", "min": 0, "max": double.infinity},
          },
        },
      },
      "branch": {
        "description": "Branch element, can have children and decoration",
        "inheritsFrom": "uielement",
        "availableProperties": ["decoration.", "content."],
        "defaultValues": {
          "decoration": null,
          "content": null,
        },
      },
      "leaf": {
        "description":
            "Leaf element, used to present content that can't have children, like media",
        "inheritsFrom": "uielement",
      },
    },
    "elements": {
      "empty": {
        "description": "Empty branch element",
        "inheritsFrom": "branch",
      },
      "box": {
        "description": "Branch element with default box decoration",
        "inheritsFrom": "branch",
        "defaultValues": {
          "decoration": {
            "backgroundColor": "#FFFFFFFF",
            "radius": "0.0",
            "border": {
              "all": {
                "width": "1.0",
                "color": "#000000FF",
              },
            },
          }
        },
      },
      "text": {
        "description": "Text element with default text decoration",
        "inheritsFrom": "leaf",
        "availableProperties": [
          "text",
          "fontSize",
          "fontWeight",
          "color",
          "alignment"
        ],
        "defaultValues": {
          "text": "My text",
          "fontSize": "16.0",
          "fontWeight": "normal",
          "color": "#000000FF",
          "alignment": ""
        },
      },
      "image": {
        "description": "Image element with default image decoration",
        "inheritsFrom": "leaf",
        "availableProperties": ["imagePath", "source", "fit", "alignment"],
        "defaultValues": {
          "imagePath": "",
          "source": "url",
          "fit": "cover",
          "alignment": "center",
        },
      },
      "icon": {
        "description":
            "Icon element with default color. Icon size is min(width, height)",
        "inheritsFrom": "leaf",
        "availableProperties": ["icon", "color"],
        "defaultValues": {
          "color": "#000000FF",
        },
      },
    },
    "properties": {
      "width": {
        "description": "Width of element.",
        "type": "axisSize",
      },
      "height": {
        "description": "Height of element.",
        "type": "axisSize",
      },
      "decoration.": {
        "description": "Decoration of element.",
        "subProperties": {
          "backgroundColor": {
            "type": "hex",
            "description": "Background color of element.",
            "format": "#RRGGBBAA",
          },
          "radius": {
            "description": "Radius of element.",
            "type": "number",
            "format": "as string",
            "defaultValue": "0.0",
          },
          "border": {
            "type": "object",
            "description":
                "Border of element. Border is object with properties for each side of element. Each side can have width and color.",
            "properties": {
              "oneOf": [
                {
                  "all": {
                    "type": "borderSide",
                  }
                },
                {
                  "top": {
                    "type": "borderSide",
                  }
                },
                {
                  "bottom": {
                    "type": "borderSide",
                  }
                },
                {
                  "left": {
                    "type": "borderSide",
                  }
                },
                {
                  "right": {
                    "type": "borderSide",
                  }
                }
              ]
            },
          },
        }
      },
      "content.": {
        "description": "Content of element.",
        "subProperties": {
          "type.": {
            "description":
                "Type of content. Single type has exactly 1 child and flex type has more than 1 children.",
            "subProperties": {
              "condition": {
                "condition": "children.length == 1",
                "true": {
                  "alignment": {
                    "type": "string",
                    "description": "Alignment of content.'",
                    "enum": [
                      "topLeft",
                      "topCenter",
                      "topRight",
                      "centerLeft",
                      "center",
                      "centerRight",
                      "bottomLeft",
                      "bottomCenter",
                      "bottomRight"
                    ],
                    "defaultValue": "center",
                  },
                },
                "false": {
                  "direction": {
                    "type": "string",
                    "description": "Direction of content.",
                    "enum": ["vertical", "horizontal"],
                    "defaultValue": "vertical",
                  },
                  "mainAxisAlignment": {
                    "type": "string",
                    "description": "Main axis alignment of content.",
                    "enum": [
                      "start",
                      "end",
                      "center",
                      "spaceBetween",
                      "spaceAround",
                      "spaceEvenly"
                    ],
                    "defaultValue": "start",
                  },
                  "crossAxisAlignment": {
                    "type": "string",
                    "description": "Cross axis alignment of content.",
                    "enum": [
                      "start",
                      "end",
                      "center",
                      "stretch",
                      "baseline",
                      "spaceBetween",
                      "spaceAround",
                      "spaceEvenly"
                    ],
                    "defaultValue": "start",
                  },
                  "spacing": {
                    "type": "number",
                    "description": "Spacing between children.",
                    "format": "as string",
                    "defaultValue": "0.0",
                  }
                }
              }
            }
          },
          "padding": {
            "description": "Padding of content.",
            "type": "padding",
          },
          "overflow": {
            "description":
                "Overflow of content. Overflow is object with properties for each side of element. Each side can have width and color.",
            "type": "object",
            "enum": ["allow", "clip", "verticalScroll", "horizontalScroll"],
            "defaultValue": "allow",
          },
        }
      },
      "text": {
        "description": "Text of text element.",
        "type": "string",
      },
      "fontSize": {
        "description": "Font size of text element.",
        "type": "number",
        "format": "as string"
      },
      "fontWeight": {
        "description": "Font weight of text element.",
        "type": "string",
        "enum": [
          "thin",
          "extralight",
          "light",
          "regular",
          "medium",
          "semibold",
          "bold",
          "extrabold",
          "black",
        ],
        "defaultValue": "regular",
      },
      "icon": {
        "description": "codepoint of lucide icon.",
        "type": "integer",
        "format": "as string",
        "minimum": "57400",
        "maximum": "58960",
        "defaultValue": "57400",
      },
      "color": {
        "description": "Color of text or icon.",
        "type": "hex",
        "format": "#RRGGBBAA",
      },
      "alignment": {
        "description": "Alignment of text or image.",
        "type": "string",
        "enum": [
          "topLeft",
          "topCenter",
          "topRight",
          "centerLeft",
          "center",
          "centerRight",
          "bottomLeft",
          "bottomCenter",
          "bottomRight"
        ],
        "defaultValue": "center",
      },
      "source": {
        "description": "Source of image.",
        "type": "string",
        "enum": ["url", "asset"],
        "defaultValue": "asset",
      },
      "imagePath": {
        "description": "Path to image.",
        "type": "string",
        "defaultValue": "assets/images/placeholder.png",
      },
      "fit": {
        "description": "Fit of image.",
        "type": "string",
        "enum": [
          "contain",
          "cover",
          "fill",
          "fitWidth",
          "fitHeight",
          "scaleDown",
          "none"
        ],
        "defaultValue": "cover",
      },
    },
    "types": {
      "axisSize": {
        "oneOf": [
          {
            "type": "controlled",
            "description": "Fixed size for element",
            "properties": {
              "value": {
                "type": "number",
                "description": "Fixed size for element",
                "format": "as string",
              },
            },
          },
          {
            "type": "expand",
            "description": "Tries to fill all available space",
            "properties": {
              "min": {
                "type": "number",
                "description": "Min size for element",
                "format": "as string",
                "defaultValue": "0",
              },
              "max": {
                "type": "number",
                "description": "Max size for element",
                "format": "as string",
                "defaultValue": "inf",
              },
              "flex": {
                "type": "number",
                "description":
                    "If multiple elements are using expand, this is used to determine how much space each element gets in relation to available space.",
                "format": "as string",
                "defaultValue": "1",
              },
            },
          },
          {
            "type": "hug",
            "description": "",
            "properties": {
              "min": {
                "type": "number",
                "description": "Min size for element",
                "format": "as string",
                "defaultValue": "0",
              },
              "max": {
                "type": "number",
                "description": "Max size for element",
                "format": "as string",
                "defaultValue": "inf",
              },
            },
          }
        ],
      },
      "borderSide": {
        "weight": {
          "type": "number",
          "description": "Weight of border.",
          "format": "as string",
        },
        "color": {
          "type": "hex",
          "description": "Color of border.",
          "format": "#RRGGBBAA",
        },
      },
      "padding": {
        "type": "object",
        "description":
            "Padding of element. Padding is object with properties for each side of element. Each side can have width and color.",
        "properties": {
          "top": {
            "type": "number",
            "description": "Top padding",
            "format": "as string",
          },
          "bottom": {
            "type": "number",
            "description": "Bottom padding",
            "format": "as string",
          },
          "left": {
            "type": "number",
            "description": "Left padding",
            "format": "as string",
          },
          "right": {
            "type": "number",
            "description": "Right padding",
            "format": "as string",
          },
        },
      },
    },
  };

  static const String editData = '''
    You are given a JSON representation of a UI design. You need to edit this design to make it more visually appealing and user-friendly. You can add, remove or modify elements in the design to achieve this.
    But remember, that JSON needs to follow same format as the original design.
    You are also given a detailed prompt that explains the structure of the design and the actions that need to be performed. Use this prompt as a guide to make the necessary changes to the design.
    Here is also some additional information about the data models, that JSON will be deserialized to:
    $full
  ''';

  static const String full = '''
  You are professional UI designer that can create cool UI design for really structured JSON format. I give you some pseudo code blocks so you know structure that the JSON needs to be in.
  Notice that you need to give numbers as strings. Also remember that singleType content has exactly 1 child and flexType content has more than 1 children. 
  Icons use Lucide family with codepoint range 57400-58960. Other pictures than placeholder are not supported.
  
//basemodel for UIElements
model UIElement
{
'type':  'branch'
'width': model AxisSize
'height': model AxisSize
optional 'decoration': model Decoration
optional 'content': model Content
}

//Size settings for UIElement
//Size is fixed
model ControlledSize extends AxisSize
{
'type': 'controlled'
'value': double.toString() //Fixed size for element
}
//Size expands
model ExpandingSize extends AxisSize
{
'type': 'expand'
'min': double.toString() , range[0.0-inf] //Used to set min size for element, usually 0
'max':double.toString() , range[0.0-inf] //Used to set max size for element, usually inf
'flex': int.toString() , range[1-16]
}

model Decoration
{
'backgroundColor': hex[RRGGBBAA]
'radius': double.toString()
}

model Content
{
'type': model ContentType
'children': UIElement[]
}

//exactly 1 child required
model SingleType extends ContentType
{
'type': 'single'
}

//more than 1 children required
model FlexType extends ContentType
{
'type': 'flex'
'direction': 'vertical' or 'horizontal'
}
  ''';

  static const String wireframe = '''
    {
      'flex': {
        'width': '\$res',
        'height': '\$res',
        'direction': 'vertical',
        'children':
        [         
          {
            'container': {
              'width': 'expand',
              'height': 'hug',
              'children': [             
                'text'
              ]
            }
          },
          {
            'box': {
              'width': 'expand',
              'height': 'expand',          
            }
          },
        ]
      }
    }
    ''';

  static const String wireframeactions = '''
    [
      'addT(box, null)',
      'addT(box, down)',
      '0/addT(text, null)',
    ]
    ''';

  static const String decorationActions = '''
    [
      '1/setBackgroundColor(#FF0000FF)',
      '0/0/setFontWeight(bold)',
    ]
    ''';

  static const String devPromtWithSchema = '''
    You are professional UI designer that can create cool UI design. You utilize design thinking in you design process.
    You generate design by creating actions according to schema. These actions are then used to create UI design.
    ''';

  static const Map<String, dynamic> actionschema = {
    "type": "json_schema",
    "json_schema": {
      "name": "design_actions",
      "description": "Generate list of actions to create UI design",
      "schema": {
        "type": "object",
        "properties": {
          "actions": {
            "type": "array",
            "description": "List of actions to create UI design",
            "items": {
              "anyOf": [
                _addSchema,
                _updateSchema,
              ]
            }
          }
        },
        "required": ["actions"],
        "additionalProperties": false,
      },
      "strict": true,
    }
  };

  static const Map<String, dynamic> _commandrules = {
    "ifIsNotRoot": {
      // Changed from "if (!root)"
      "expandWidth, expandHeight": {
        "description": "Element tries to fill all available space in the axis.",
        "optionalArguments": {
          "min": {
            "type": "number",
            "description": "Minimum size for the element.",
            "format": "string",
            "defaultValue": "0",
          },
          "max": {
            "type": "number",
            "description": "Maximum size for the element.",
            "format": "string",
            "defaultValue": "inf",
          },
          "flex": {
            "type": "integer",
            "description":
                "Determines how much space the element gets relative to others using expand.",
            "format": "string",
            "defaultValue": "1",
          },
        },
      },
      "hugWidth, hugHeight": {
        "description": "Element adjusts size to fit its content.",
        "optionalArguments": {
          "min": {
            "type": "number",
            "description": "Minimum size for the element.",
            "format": "string",
            "defaultValue": "0",
          },
          "max": {
            "type": "number",
            "description": "Maximum size for the element.",
            "format": "string",
            "defaultValue": "inf",
          },
        },
      },
      "controlledWidth, controlledHeight": {
        "description": "Element has a fixed size in the axis.",
        "requiredArguments": {
          "value": {
            "type": "number",
            "description": "Fixed size for the element.",
            "format": "string",
          },
        },
      },
    },
    "ifIsBranch": {
      // Changed from "if (branch)"
      "addChild": {
        "description": "Add a new child to the element.",
        "optionalArguments": {
          "element": {
            "type": "enum",
            "description":
                "Type of element to add. Null copies the previous child or creates an empty branch if no children exist.",
            "enumValues": ["branch", "text", "image", "icon"],
          },
          "direction": {
            "type": "enum",
            "description":
                "Direction to add the element. Up/down creates vertical flex; left/right creates horizontal flex.",
            "enumValues": ["top", "bottom", "left", "right"],
          },
        },
      },
      "setBackgroundColor": {
        "description": "Set the background color of the element.",
        "optionalArguments": {
          "color": {
            "type": "hex",
            "description": "Background color in #RRGGBBAA format.",
            "defaultValue": "#00000000",
          },
        },
      },
      "setRadius": {
        "description": "Set the corner radius of the element.",
        "requiredArguments": {
          "corner": {
            "type": "enum",
            "description": "Corner to set the radius for.",
            "enumValues": [
              "topLeft",
              "topRight",
              "bottomLeft",
              "bottomRight",
              "all"
            ],
            "defaultValue": "all",
          },
          "radius": {
            "type": "number",
            "description": "Radius value.",
            "format": "string",
            "defaultValue": "0.0",
          },
        },
      },
      "setBorder": {
        "description": "Set the border of the element.",
        "optionalArguments": {
          "side": {
            "type": "enum",
            "description": "Side of the element to set the border for.",
            "enumValues": ["top", "bottom", "left", "right", "all"],
            "defaultValue": "all",
          },
          "width": {
            "type": "number",
            "description": "Border width.",
            "format": "string",
            "defaultValue": "1.0",
          },
          "color": {
            "type": "hex",
            "description": "Border color in #RRGGBBAA format.",
            "defaultValue": "#000000FF",
          },
        },
      },
      "ifHasChildren": {
        // Changed from "if (children > 0)"
        "setPadding": {
          "description": "Set padding for the element.",
          "optionalArguments": {
            "side": {
              "type": "enum",
              "description": "Side to set padding for.",
              "enumValues": ["top", "bottom", "left", "right", "all"],
              "defaultValue": "all",
            },
            "padding": {
              "type": "number",
              "description": "Padding value.",
              "format": "string",
              "defaultValue": "0.0",
            },
          },
        },
        "setOverflow": {
          "description": "Set overflow behavior for the element.",
          "optionalArguments": {
            "overflow": {
              "type": "enum",
              "description": "Overflow behavior.",
              "enumValues": [
                "allow",
                "clip",
                "verticalScroll",
                "horizontalScroll"
              ],
              "defaultValue": "clip",
            },
          },
        },
        "ifHasSingleChild": {
          // Changed from "if (children == 1)"
          "setAlignment": {
            "description": "Set alignment for the single child.",
            "optionalArguments": {
              "alignment": {
                "type": "enum",
                "description": "Alignment value.",
                "enumValues": [
                  "topLeft",
                  "topCenter",
                  "topRight",
                  "centerLeft",
                  "center",
                  "centerRight",
                  "bottomLeft",
                  "bottomCenter",
                  "bottomRight"
                ],
                "defaultValue": "center",
              },
            },
          },
        },
        "else": {
          "setDirection": {
            "description": "Set direction for multiple children.",
            "optionalArguments": {
              "direction": {
                "type": "enum",
                "description": "Direction value.",
                "enumValues": ["vertical", "horizontal"],
                "defaultValue": "vertical",
              },
            },
          },
          "setMainAxisAlignment": {
            "description": "Set main axis alignment.",
            "optionalArguments": {
              "mainAxisAlignment": {
                "type": "enum",
                "description": "Main axis alignment value.",
                "enumValues": [
                  "start",
                  "end",
                  "center",
                  "spaceBetween",
                  "spaceAround",
                  "spaceEvenly"
                ],
                "defaultValue": "start",
              },
            },
          },
          "setCrossAxisAlignment": {
            "description": "Set cross axis alignment.",
            "optionalArguments": {
              "crossAxisAlignment": {
                "type": "enum",
                "description": "Cross axis alignment value.",
                "enumValues": [
                  "start",
                  "end",
                  "center",
                  "stretch",
                  "baseline",
                  "spaceBetween",
                  "spaceAround",
                  "spaceEvenly"
                ],
                "defaultValue": "start",
              },
            },
          },
          "setSpacing": {
            "description": "Set spacing between children.",
            "optionalArguments": {
              "spacing": {
                "type": "number",
                "description": "Spacing value.",
                "format": "string",
                "defaultValue": "0.0",
              },
            },
          },
        },
      },
    },
    "else": {
      "ifIsText": {
        // Changed from "if (text)"
        "setText": {
          "description": "Set the text content.",
          "optionalArguments": {
            "text": {
              "type": "string",
              "description": "Text content.",
              "defaultValue": "My text",
            },
          },
        },
        "setFontSize": {
          "description": "Set the font size.",
          "optionalArguments": {
            "fontSize": {
              "type": "number",
              "description": "Font size value.",
              "format": "string",
              "defaultValue": "16.0",
            },
          },
        },
        "setFontWeight": {
          "description": "Set the font weight.",
          "optionalArguments": {
            "fontWeight": {
              "type": "enum",
              "description": "Font weight value.",
              "enumValues": [
                "thin",
                "extralight",
                "light",
                "regular",
                "medium",
                "semibold",
                "bold",
                "extrabold",
                "black"
              ],
              "defaultValue": "regular",
            },
          },
        },
        "setColor": {
          "description": "Set the text color.",
          "optionalArguments": {
            "color": {
              "type": "hex",
              "description": "Text color in #RRGGBBAA format.",
              "defaultValue": "#000000FF",
            },
          },
        },
      },
      "ifIsImage": {
        // Changed from "if (image)"
        "setImagePath": {
          "description": "Set the image path.",
          "optionalArguments": {
            "path": {
              "type": "string",
              "description": "Image path or URL.",
              "defaultValue": "placeholder.png",
            },
          },
        },
        "setSource": {
          "description": "Set the image source.",
          "optionalArguments": {
            "source": {
              "type": "enum",
              "description": "Image source type.",
              "enumValues": ["url", "asset"],
              "defaultValue": "asset",
            },
          },
        },
        "setFit": {
          "description": "Set the image fit.",
          "optionalArguments": {
            "fit": {
              "type": "enum",
              "description": "Image fit value.",
              "enumValues": [
                "contain",
                "cover",
                "fill",
                "fitWidth",
                "fitHeight",
                "scaleDown",
                "none"
              ],
              "defaultValue": "cover",
            },
          },
        },
      },
      "ifIsIcon": {
        // Changed from "if (icon)"
        "setIcon": {
          "description": "Set the icon.",
          "optionalArguments": {
            "icon": {
              "type": "string",
              "description": "Icon name from the Lucide family.",
              "format":
                  "lowercase, words separated by '-'. Example: 'star-off'.",
              "defaultValue": "star",
            },
          },
        },
        "setColor": {
          "description": "Set the icon color.",
          "optionalArguments": {
            "color": {
              "type": "hex",
              "description": "Icon color in #RRGGBBAA format.",
              "defaultValue": "#000000FF",
            },
          },
        },
      },
    },
  };

  static const Map<String, dynamic> _commandschema = {
    "type": "json_schema",
    "json_schema": {
      "name": "design_actions",
      "schema": {
        "description": "Generate list of commands to create UI design",
        "type": "object",
        "properties": {
          "actions": {
            "type": "array",
            "description":
                "List of commands to create UI design. Be logical in the order of actions. Actions are executed in the order they are given.",
            "items": {
              "type": "object",
              "properties": {
                "target": {
                  "type": "array",
                  "description":
                      "Path to target element. Leave path empty if target is root element. Remember that you can't target element that is not created yet. For example [1] is second child of root element, so you need to add at least 2 children to root first.",
                  "items": {
                    "type": "integer",
                    "description": "Index of element in path."
                  }
                },
                "action": {
                  "type": "string",
                  "description":
                      "Action to perform. Look at rules what actions are available for given target."
                },
                "arguments": {
                  "type": "array",
                  "description":
                      "Arguments for action. Look at rules what arguments are required or available for given action.",
                  "items": {
                    "type": "object",
                    "properties": {
                      "name": {
                        "type": "string",
                        "description": "Name of argument."
                      },
                      "value": {
                        "type": ["string"],
                        "description": "Value of argument."
                      }
                    },
                    "required": ["name", "value"],
                    "additionalProperties": false
                  }
                }
              },
              "required": ["target", "action", "arguments"],
              "additionalProperties": false
            }
          }
        },
        "required": ["actions"],
        "additionalProperties": false
      },
      "strict": true
    }
  };

  static const Map<String, dynamic> _addSchema = {
    "type": "object",
    "description":
        "Action to create new element as child of target. This action will output the new element, so it can be used as target for subsequent actions.",
    "properties": {
      "action": {
        "type": "string",
        "description": "always 'add'",
        "const": "add",
      },
      "target": _targetSchema,
      "element": {
        "type": "string",
        "description": "Element type to add",
        "enum": ["empty", "box", "text", "image", "icon"],
      },
      "direction": {
        "type": ["string", "null"],
        "description":
            "Direction to add element in. Does nothing if element has no other children. Up or down will create vertical flex, left or right will create horizontal flex.",
        "enum": ["top", "bottom", "left", "right"],
      },
    },
    "required": ["action", "target", "element", "direction", "then"],
    "additionalProperties": false,
  };

  static const Map<String, dynamic> _updateSchema = {
    "type": "object",
    "description":
        "Action to create new element as child of target. This action will output the new element, so it can be used as target for subsequent actions.",
    "properties": {
      "action": {
        "type": "string",
        "description": "always 'update'",
        "const": "update",
      },
      "target": _targetSchema,
      "property": {
        "type": "string",
        "description": "Name of property to update. Look ",
      }
    },
    "required": ["action", "target", "field", "value"],
    "additionalProperties": false,
  };

  /*{
        "type": "string",
        "description":
            "Field to update. Give color as hex string. Icon, image and text have no decoration or content.",
        "enum": [
          "width.value",
          "width.min",
          "width.max",
          "width.flex",
          "height.value",
          "height.min",
          "height.max",
          "height.flex",
          "decoration.backgroundColor",
          "decoration.radius",
          "decoration.borderwidth",
          "decoration.bordercolor",
          "content.direction",
          "content.mainAxisAlignment",
          "content.crossAxisAlignment",
        ],
      },
      "value": {
        "type": "string",
        "description": "Value to set field to",
      },*/

  static const Map<String, dynamic> _targetSchema = {
    "type": "object",
    "properties": {
      "format": {
        "type": "string",
        "description":
            "Format of target. Normally 'path', but inside 'then' it can be 'output'. Path is list of indexes to navigate to target element. .",
        "enum": ["output", "path"],
      },
      "path": {
        "type": "array",
        "description":
            "Path to target element. Leave path empty if output is used or targeting root element.",
        "items": {
          "type": "number",
        },
      },
    },
    "required": ["format", "path"],
    "additionalProperties": false,
  };

  static const Map<String, dynamic> _addTool = {
    "type": "function",
    "name": "add",
    "description":
        "Add a new UI element as a child of the target element. Specify the type of element to add and the direction in which to add it.",
    "parameters": {
      "type": "object",
      "properties": {
        "target": {
          "type": "array",
          "description":
              "Path to target element. Leave path empty if target is root element.",
          "items": {
            "type": "integer",
            "description": "Index of element in path",
          },
        },
        "element": {
          "type": "string",
          "description":
              "Type of element to add. Null will copy previous child of target, or if not chilren present, create empty element.",
          "enum": ["empty", "box", "text", "image", "icon", "null"],
        },
        "direction": {
          "type": ["string", "null"],
          "description":
              "Direction to add the element in. Does nothing if the target has no children. Up or down will create vertical flex, left or right will create horizontal flex.",
          "enum": ["top", "bottom", "left", "right"],
        },
      },
      "required": ["target", "element", "direction"],
      "additionalProperties": false,
    },
    "strict": true,
  };

  static const Map<String, dynamic> _updateTool = {
    "type": "function",
    "name": "update",
    "description":
        "Update property of an UI element (target) according to given rules.",
    "parameters": {
      "type": "object",
      "properties": {
        "target": {
          "type": "array",
          "description":
              "Path to target element. Leave path empty if target is root element.",
          "items": {
            "type": "integer",
            "description": "Index of element in path",
          },
        },
        "property": {
          "type": "string",
          "description":
              "Property to update. Follow given rules on available properties. You need to remember the type of target element, to know them.",
        },
        "value": {
          "type": "string",
          "description":
              "Value to set property to. Follow given rules on what kind of input is expected.",
        },
      },
      "required": ["target", "property", "value"],
      "additionalProperties": false,
    },
    "strict": true,
  };
}
