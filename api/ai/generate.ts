import { openai } from '@ai-sdk/openai';
import { streamText, tool } from 'ai';
import { z } from 'zod';

const actionSchema = z.object({
  target: z.array(z.number()),
  action: z.string(),
  arguments: z.array(z.object({
    name: z.string(),
    value: z.string()
  }))
});

const actionsSchema = z.object({
  actions: z.array(actionSchema)
});

// Reusable schemas
const targetSchema = z.array(z.number()).describe('Path to target element. Empty array [] for root element.');

// Developer prompts
const EXTEND_PROMPT_SYSTEM = `You are a professional UI designer tasked with extending the given prompt to create a high-quality draft for a UI design. Your goal is to provide a creative, visually appealing, and user-friendly design foundation that serves as an excellent starting point for a human designer to refine. 

Focus on the following principles:
- **Clarity and Usability**: Ensure the design is intuitive and easy to navigate for users.
- **Visual Appeal**: Use appropriate colors, spacing, and alignment to create an aesthetically pleasing layout.
- **Responsiveness**: Assume the design should work seamlessly on both mobile and desktop platforms unless otherwise specified.`;

const INITIAL_ACTIONS_SYSTEM = `You are a professional UI designer tasked with creating a UI design based on the given prompt.

Rules for available actions:
1. The design is represented as a tree structure where the root element is the starting point.
2. Use the target path to specify the position of each element in the hierarchy:
   - [] refers to the root element
   - [0] refers to the first child of the root element
   - [1, 2] refers to the third child of the second child of the root element
3. Always create parent elements before adding child elements
4. Element types:
   - Branch elements (empty, box) can have children and decoration
   - Leaf elements (text, image, icon) present content without children
5. Think about the design hierarchy and create a logical structure

Follow these steps:
1. Understand the design requirements from the prompt
2. Start building from the root element and add necessary children
3. Set appropriate properties for each element
4. Ensure the design is visually appealing and user-friendly`;

export async function extendPromptStream(original: string, onData: (action: string) => void): Promise<void> {
  const result = streamText({
    model: openai.responses('gpt-4o'),
    messages: [
      { 
        role: 'system', 
        content: EXTEND_PROMPT_SYSTEM
      },
      { role: 'user', content: original },
    ],
  });

  for await (const chunk of result as any) {
    onData(chunk);
  }
}

export async function initialActionsStream(prompt: string, onData: (action: any) => void): Promise<void> {
  const result = streamText({
    model: openai.responses('gpt-4o'),
    messages: [
      { 
        role: 'system', 
        content: INITIAL_ACTIONS_SYSTEM
      },
      { role: 'user', content: prompt },
    ],
    tools: {
      addChild: tool({
        description: 'Add a new child to the target element.',
        parameters: z.object({
          target: targetSchema,
          element: z.enum(['branch', 'text', 'image', 'icon']).describe('Type of element to add'),
          direction: z.enum(['top', 'bottom', 'left', 'right']).optional().describe('Direction to add the element. Up/down creates vertical flex; left/right creates horizontal flex. Has effect only when adding second child to a branch element.')
        })
      }),
      setSize: tool({
        description: 'Set the size of an element (width or height). Not available for the root element.',
        parameters: z.object({
          target: targetSchema,
          dimension: z.enum(['width', 'height']).describe('Which dimension to set.'),
          sizeType: z.enum(['expand', 'hug', 'controlled']).describe('Type of sizing to use.'),
          value: z.string().optional().describe('Value for controlled size'),
          min: z.string().optional().describe('Minimum size for expand or hug.'),
          max: z.string().optional().describe('Maximum size for expand or hug.'),
          flex: z.string().optional().describe('Flex value for expand (how much space to take relative to siblings).')
        })
      }),
      setDecoration: tool({
        description: 'Set visual decoration properties for an element. Available only for branch elements.',
        parameters: z.object({
          target: targetSchema,
          backgroundColor: z.string().optional().describe('Background color in #RRGGBBAA format.'),
          border: z.object({
            side: z.enum(['top', 'bottom', 'left', 'right', 'all']).describe('Which border side to set.'),
            width: z.string().describe('Border width as string number.'),
            color: z.string().describe('Border color in #RRGGBBAA format.')
          }).optional(),
          radius: z.object({
            corner: z.enum(['topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'all']).describe('Which corner to set the radius for.'),
            value: z.string().describe('Radius value as string number.')
          }).optional()
        })
      }),
      setPadding: tool({
        description: 'Set the padding of the element. Available only for branch elements with children.',
        parameters: z.object({
          target: targetSchema,
          side: z.enum(['top', 'bottom', 'left', 'right', 'all']).describe('Which side to set padding for.'),
          padding: z.string().describe('Padding value as string number.')
        })
      }),
      setSingleChildAlignment: tool({
        description: 'Set alignment for single child content. Available only for branch elements with exactly one child.',
        parameters: z.object({
          target: targetSchema,
          alignment: z.enum([
            'topLeft', 'topCenter', 'topRight',
            'centerLeft', 'center', 'centerRight',
            'bottomLeft', 'bottomCenter', 'bottomRight'
          ]).describe('Alignment value.')
        })
      }),
      setMultiChildProps: tool({
        description: 'Set properties for elements with multiple children. Available only for branch elements with more than one child.',
        parameters: z.object({
          target: targetSchema,
          direction: z.enum(['vertical', 'horizontal']).describe('Direction for layout.'),
          gap: z.string().optional().describe('Gap between children as string number.'),
          justifyContent: z.enum(['start', 'end', 'center', 'spaceBetween', 'spaceAround', 'spaceEvenly']).optional().describe('How to distribute space between children.'),
          alignItems: z.enum(['start', 'end', 'center', 'stretch', 'baseline']).optional().describe('How to align children in the cross axis.')
        })
      }),
      setText: tool({
        description: 'Set the text content for a text element. Available only for text elements.',
        parameters: z.object({
          target: targetSchema,
          text: z.string().describe('Text content.')
        })
      }),
      setTextStyle: tool({
        description: 'Set the style for a text element. Available only for text elements.',
        parameters: z.object({
          target: targetSchema,
          fontSize: z.string().describe('Font size value as string number.'),
          fontWeight: z.enum(['thin', 'extralight', 'light', 'regular', 'medium', 'semibold', 'bold', 'extrabold', 'black']).describe('Font weight value.'),
          color: z.string().describe('Text color in #RRGGBBAA format.')
        })
      }),
      setImageProps: tool({
        description: 'Set properties for an image element. Available only for image elements.',
        parameters: z.object({
          target: targetSchema,
          path: z.string().describe('Image path or URL.'),
          source: z.enum(['url', 'asset']).describe('Image source type.'),
          fit: z.enum(['contain', 'cover', 'fill', 'fitWidth', 'fitHeight', 'scaleDown', 'none']).describe('How the image should be fitted in its space.')
        })
      }),
      setIcon: tool({
        description: 'Set properties for an icon element. Available only for icon elements.',
        parameters: z.object({
          target: targetSchema,
          icon: z.string().describe('Icon codepoint from Lucide family (57400-58960).'),
          color: z.string().describe('Icon color in #RRGGBBAA format.')
        })
      })
    }
  });

  for await (const chunk of result as any) {
    onData(chunk);
  }
}