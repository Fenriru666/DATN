import { GoogleGenerativeAI, SchemaType } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

const tools = [
  {
    functionDeclarations: [
      {
        name: 'triggerRideBooking',
        description: 'Call this function when the user wants to book a ride.',
        parameters: {
          type: SchemaType.OBJECT,
          properties: {
            destination: {
              type: SchemaType.STRING,
              description: 'The location',
            }
          },
          required: ['destination'],
        },
      }
    ],
  },
];

async function run() {
  try {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash',
      tools: tools,
      systemInstruction: "You are a helpful AI.",
    });

    const chat = model.startChat({ history: [] });
    const result = await chat.sendMessage('Hello');
    console.log(result.response.text());
  } catch (error) {
    console.error('ERROR:', error.message);
  }
}

run();
