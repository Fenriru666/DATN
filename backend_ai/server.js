import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import admin from 'firebase-admin';

import fs from 'fs';

dotenv.config();

// Initialize Firebase Admin (Requires SERVICE_ACCOUNT_KEY json)
// In production, use the file path or stringified JSON from ENV
let db = null;
try {
  // Option 1: Load from local file if exists
  const serviceAccount = JSON.parse(fs.readFileSync('./serviceAccountKey.json', 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  db = admin.firestore();
  console.log('Firebase Admin Initialized Successfully.');
} catch (error) {
  console.warn('⚠️ Firebase Admin Initialization Failed. Please add serviceAccountKey.json to this directory.');
}

const app = express();
app.use(cors());
app.use(express.json());

// No remote API initialization needed since we will use Localhost (Ollama)

// Define the Tools (Functions) that Gemini can use
const tools = [
  {
    type: 'function',
    function: {
      name: 'triggerRideBooking',
      description: 'ONLY call this function if the user EXPLICITLY asks to book a ride, needs a vehicle, or wants to go to a specific destination. NEVER call this for greetings like "hello" or "xin chao".',
      parameters: {
        type: 'object',
        properties: {
          destination: {
            type: 'string',
            description: 'The location the user wants to go to.',
          },
          vehicleType: {
            type: 'string',
            description: 'The type of vehicle, like "bike" or "car". Optional.',
          }
        },
        required: ['destination'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'searchFoodByCategoryOrMood',
      description: 'ONLY call this function if the user EXPLICITLY says they are hungry, thirsty, want to eat a specific food, or want to order food. NEVER call this for greetings like "hello" or "xin chao".',
      parameters: {
        type: 'object',
        properties: {
          categoryOrMood: {
            type: 'string',
            description: 'The kind of food or the mood of the user (e.g. "sweet", "pizza", "sad", "thirsty").',
          }
        },
        required: ['categoryOrMood'],
      },
    },
  }
];

// Define Partner Tools (Merchant/Driver)
const partnerTools = [
  {
    type: 'function',
    function: {
      name: 'getBusinessStatistics',
      description: 'Call this function when the business partner (merchant/driver) asks for their revenue, statistics, orders, or business performance.',
      parameters: {
        type: 'object',
        properties: {
          timeframe: {
            type: 'string',
            description: 'The time period they are asking for, e.g., "today", "this_week", "this_month".',
          }
        },
      },
    },
  },
];

const CONSUMER_PROMPT = `You are a helpful and intelligent AI Assistant for a Super App that has Ride-hailing and Food Delivery services. 
IMPORTANT RULES:
1. ALWAYS reply in Vietnamese friendly and naturally.
2. For small talk, greetings (xin chào, hi), or questions about how to use the app (e.g. "làm sao để đặt xe?"), you MUST REPLY NORMALLY with text.
3. ONLY IF the user says EXACTLY where they want to go (e.g., "đặt xe tới Đà Nẵng", "tôi muốn đi vincom", "đặt xe từ Nguyễn Trãi về Tuy Lý Vương"), you MUST output ONLY this JSON without any other text and no markdown formatting:
{"tool": "triggerRideBooking", "destination": "<where they want to go>", "pickup": "<where they depart from, if mentioned>"}
Note: If the user doesn't mention their departure location, do not include the "pickup" field. Just output the destination.
4. ONLY IF the user says they want to eat a specific food (e.g., "tôi muốn ăn phở", "đói quá"), you MUST output ONLY this JSON without any other text and no markdown formatting:
{"tool": "searchFoodByCategoryOrMood", "categoryOrMood": "<food kind>"}
5. If the user asks specifically about CSKH policies like forgotten password, output ONLY this JSON without any other text: {"tool": "searchCustomerSupportFAQ", "query": "<their question>"}
6. OUT OF SCOPE: If the user asks about ANYTHING ELSE (coding, math, history), you MUST refuse to answer and say: "Dạ em là trợ lý Ảo hỗ trợ Đặt Xe và Giao Thức Ăn. Với yêu cầu chuyên sâu khác, Sếp vui lòng liên hệ Tổng Đài ạ!"`;

const PARTNER_PROMPT = "You are a highly analytical Business Intelligence AI Assistant. You specialize in analyzing data, generating revenue reports, and providing business insights. You are talking to a Business Partner (Merchant). \nIMPORTANT RULES:\n1. ALWAYS reply in Vietnamese (Tiếng Việt) professionally.\n2. Only use Data Tools when they explicitly ask about their revenue, orders, or statistics.\n3. For general greetings or questions unrelated to data, reply normally.";

const DRIVER_PROMPT = `Bạn là một Trợ lý AI Chuyên viên hỗ trợ Đối tác Tài xế (Driver) của một siêu ứng dụng (Super App).
IMPORTANT RULES:
1. ALWAYS reply naturally in friendly Vietnamese. Xưng hô là "Em" hoặc "Hệ thống", gọi tài xế là "Sếp" hoặc "Bác tài".
2. You provide guidance on topics like Hỗ trợ kiếm tiền (Tối ưu thu nhập), Hỗ trợ chuyến đi (Luật lệ, hủy cuốc, an toàn), and Kỹ thuật App (Sự cố nền tảng).
3. Be concise and supportive. Do NOT output JSON tool calls unless specifically asked to analyze data. Just answer their questions like a smart operator.
4. OUT OF SCOPE: If the user asks about ANYTHING ELSE (coding, math, history), refuse politely and say: "Dạ em là trợ lý chuyên hỗ trợ Đối tác Tài xế. Với yêu cầu chuyên sâu khác, Sếp vui lòng liên hệ Tổng Đài ạ!"`;

function sanitizeAddresses(userMessage, callArgs) {
  let pickup = callArgs.pickup || '';
  let destination = callArgs.destination || '';

  // Try to match "từ [A] đến/tới/về/sang/qua [B]" without using ASCII-only word boundaries (\b)
  const routeRegex = /(?:^|\s)từ\s+(.+?)\s+(?:đến|tới|về|sang|qua)\s+(.+)$/i;
  const routeMatch = userMessage.match(routeRegex);
  if (routeMatch) {
    pickup = routeMatch[1].trim().replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?]/g, "").trim();
    destination = routeMatch[2].trim().replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?]/g, "").trim();
  } else {
    // If only destination is present, look for "đến/tới/đi/về/sang [B]"
    const destMarkers = [
      /(?:^|\s)đến\s+(.+)$/i,
      /(?:^|\s)tới\s+(.+)$/i,
      /(?:^|\s)đi\s+(.+)$/i,
      /(?:^|\s)về\s+(.+)$/i,
      /(?:^|\s)sang\s+(.+)$/i
    ];
    for (const regex of destMarkers) {
      const match = userMessage.match(regex);
      if (match && match[1]) {
        let extracted = match[1].trim().replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?]/g, "").trim();
        if (extracted.length > 2) {
          destination = extracted;
          break;
        }
      }
    }
  }

  // Capitalize the first letter of each word to make it look professional
  const capitalize = (str) => {
    if (!str) return str;
    return str.split(' ').map(word => {
      if (!word) return '';
      return word[0].toUpperCase() + word.slice(1);
    }).join(' ');
  };

  return {
    pickup: pickup ? capitalize(pickup) : '',
    destination: destination ? capitalize(destination) : ''
  };
}

// The main Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message: userMessage, userId, role, topic, sessionId } = req.body;
    if (!userMessage) {
      return res.status(400).json({ error: 'Message is required' });
    }

    let activePrompt = CONSUMER_PROMPT;
    if (role === 'driver') {
      activePrompt = DRIVER_PROMPT;
    } else if (role === 'merchant') {
      activePrompt = PARTNER_PROMPT;
    }

    if (topic === 'ride_hailing') {
      activePrompt += " CONTEXT: The user specifically wants to book a ride. Prioritize ride-hailing tools and keep answers brief.";
    } else if (topic === 'food_delivery') {
      activePrompt += " CONTEXT: The user specifically wants to order food. Prioritize food search tools and suggest delicious options.";
    } else if (topic === 'customer_support') {
      activePrompt += " CONTEXT: The user specifically needs support or wants to complain. Be highly empathetic, apologize if necessary, and offer to resolve the issue.";
    } else if (topic === 'driver_earnings') {
      activePrompt += " CONTEXT: Sếp đang thắc mắc về Thu nhập, Hãy động viên và giải thích sự cố gắng sẽ đạt thứ hạng cao.";
    } else if (topic === 'driver_support') {
      activePrompt += " CONTEXT: Sếp đang thắc mắc về Cuốc xe, chính sách hủy chuyến, luật lệ. Hãy trả lời ngắn gọn, đặt sự an toàn lên hàng đầu.";
    } else if (topic === 'driver_tech_support') {
      activePrompt += " CONTEXT: Sếp đang gặp sự cố kỹ thuật App (GPS, không nhận được cuốc). Hãy hướng dẫn khởi động lại máy, kiểm tra ping, hoặc bật chế độ Trực Tuyến.";
    }

    console.log(`[USER ${userId || 'Anonymous'} - ROLE: ${role || 'consumer'}]: ${userMessage}`);

    // Fetch history from DB if userId and sessionId exists
    let history = [];
    if (userId && sessionId && db) {
      try {
        const chatsSnapshot = await db.collection('users').doc(userId)
          .collection('chat_sessions').doc(sessionId).collection('messages')
          .orderBy('timestamp', 'desc')
          .limit(20)
          .get();
        
        let fetchedDocs = [];
        chatsSnapshot.forEach(doc => fetchedDocs.push(doc.data()));
        
        // Reverse to maintain chronological order
        fetchedDocs.reverse().forEach(data => {
            if (data.text) {
                history.push({
                    role: data.isFromUser ? 'user' : 'assistant',
                    content: data.text
                });
            }
        });
      } catch (historyError) {
        console.error('Error fetching chat history:', historyError);
      }
    }

    // Convert to Ollama Payload format
    let messages = [{ role: 'system', content: activePrompt }];
    
    // Limit History to the last 6 messages
    let recentHistory = history;
    if (history.length > 6) {
      recentHistory = history.slice(history.length - 6);
    }
    
    messages = messages.concat(recentHistory);
    messages.push({ role: 'user', content: userMessage });

    const ollamaPayload = {
      model: 'llama3.2', // using local llama 3.2 installed by user
      messages: messages,
      stream: false,
      options: {
        temperature: 0.3, // Lower temperature to prevent creative hallucinations with tools
        top_k: 20
      }
    };

    let responseData;
    try {
      // Direct REST API call to local Ollama instance running on RTX 3060
      const response = await fetch('http://127.0.0.1:11434/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(ollamaPayload)
      });
      
      if (!response.ok) {
        throw new Error(`Ollama responded with status: ${response.status}`);
      }
      
      responseData = await response.json();
    } catch (apiError) {
      console.error('Ollama Local API Error:', apiError.message || apiError);
      return res.json({
        type: 'text',
        text: 'Não bộ AI ở máy Local chưa được kích hoạt hoặc Ollama đang tắt. Sếp hãy chắc chắn đã chạy lệnh ở CMD: "ollama run llama3.2" nha!'
      });
    }

    const aiMessage = responseData.message || {};
    let textResponse = aiMessage.content || '';
    const functionCalls = aiMessage.tool_calls;

    let isToolCalled = false;
    let call = null;

    // 1. Check if Llama 3 decided to call a function (Native Tool Call or Manual JSON Fallback)
    if (functionCalls && functionCalls.length > 0) {
      isToolCalled = true;
      call = functionCalls[0].function;
      call.args = call.arguments; // Backward compatibility with our old Gemini args format
      console.log(`[AI NATIVE TOOL CALL]: ${call.name} with args:`, call.args);
    } else {
      // Manual parser for 3B models returning JSON in text
      try {
        // Strip markdown fences first to help the regex match clean text
        let cleanMatchText = textResponse.replace(/```json/g, '').replace(/```/g, '').trim();
        const match = cleanMatchText.match(/\{[\s\S]*"tool"[\s\S]*\}/);
        if (match) {
            const parsed = JSON.parse(match[0]);
            if (parsed.tool) {
                isToolCalled = true;
                call = { 
                   name: parsed.tool, 
                   args: parsed 
                };
                console.log(`[AI MANUAL TOOL CALL]: ${call.name} with args:`, call.args);
            }
        }
      } catch (e) {
          // not a valid json tool call
          console.error("Failed to parse manual JSON fallback:", e.message);
      }
    }

    if (isToolCalled && call) {
      // --- Execute Tool Logic ---
      let toolResponseData = null;
      let uiType = 'text';
      let followUpText = '';

      if (call.name === 'triggerRideBooking') {
        const sanitized = sanitizeAddresses(userMessage, call.args);
        const dest = sanitized.destination || call.args.destination;
        const pickup = sanitized.pickup || call.args.pickup;

        if (!dest || dest.trim() === '' || dest.toLowerCase() === 'đà nẵng' || dest.toLowerCase() === 'hà nội') {
           // Bắt lỗi AI chém gió địa chỉ ảo
            uiType = 'text';
            followUpText = 'Dạ Sếp muốn đặt xe đi đâu ạ? Sếp cho em xin địa chỉ cụ thể nha (VD: 736 Nguyễn Trãi, Quận 5).';
            isToolCalled = false;
        } else {
            call.args.destination = dest;
            if (pickup) {
              call.args.pickup = pickup;
            }

            uiType = 'ride_card';
            toolResponseData = {
              pickup: pickup ? pickup : 'Vị trí hiện tại của bạn',
              dropoff: dest
            };
            
            if (pickup) {
              followUpText = `Dạ, hệ thống đã ghi nhận lộ trình từ **${pickup}** đến **${dest}**. Sếp vui lòng bấm "Tiếp tục đặt xe" để xem khoảng cách và chọn loại xe nhé!`;
            } else {
              followUpText = `Tuyệt vời! Sếp muốn đến **${dest}**. Sếp vui lòng bấm "Tiếp tục đặt xe" để bản đồ tự động tính giá cho mình nhé!`;
            }
        }
      }
      else if (call.name === 'searchFoodByCategoryOrMood') {
        // QUERY FIREBASE DB: Finding food based on mood/category mapping
        try {
          uiType = 'food_card';
          if (!db) throw new Error("Firebase không được kết nối (Thiếu serviceAccountKey.json)");
          // For simplicity in Demo, grab a random merchant or do a basic substring search on category
          const categoryKeyword = call.args.categoryOrMood.toLowerCase();
          let merchantQuery = db.collection('merchants').limit(1); // Default

          // If we had a robust category tag, we would do:
          // .where('tags', 'array-contains', categoryKeyword)

          const merchantSnapshot = await merchantQuery.get();

          if (merchantSnapshot.empty) {
            toolResponseData = null;
            followUpText = `Mình không tìm thấy cửa hàng nào phù hợp với yêu cầu "${call.args.categoryOrMood}" của bạn. Bạn thử tìm món khác nhé!`;
          } else {
            const merchantDoc = merchantSnapshot.docs[0];
            const merchantData = merchantDoc.data();

            // Fetch some menu items from this merchant's subcollection
            const menuSnapshot = await merchantDoc.ref.collection('menu').limit(2).get();
            let menuItems = [];
            let totalPrice = 0;

            menuSnapshot.forEach(itemDoc => {
              const itemData = itemDoc.data();
              menuItems.push({
                name: itemData.name,
                price: `${itemData.price.toLocaleString('vi-VN')}đ`
              });
              totalPrice += itemData.price;
            });

            if (menuItems.length === 0) {
              // Fallback dummy items if real menu is empty
              menuItems = [
                { name: `Combo giải sầu (${call.args.categoryOrMood})`, price: '65,000đ' },
                { name: 'Trà Đào Cam Sả', price: '45,000đ' }
              ];
              totalPrice = 110000;
            }

            toolResponseData = {
              restaurantName: merchantData.name,
              items: menuItems,
              total: `${totalPrice.toLocaleString('vi-VN')}đ`
            };
            followUpText = `Nghe có vẻ bạn đang muốn tìm ${call.args.categoryOrMood}. Mình gợi ý món ăn hấp dẫn từ nhà hàng **${merchantData.name}** gần bạn nhất nhé!`;
          }
        } catch (dbError) {
          console.error("Firebase FoodSearch Error:", dbError);
          uiType = 'text';
          followUpText = "Xin lỗi, đã có lỗi kết nối khi tìm kiếm nhà hàng. Bạn kiểm tra lại sao nhé.";
        }
      }
      else if (call.name === 'searchCustomerSupportFAQ') {
        // QUERY FIREBASE DB: Support FAQ Database 
        uiType = 'text';
        try {
          // Hardcoded examples for demo purposes, representing DB logic
          const q = (call.args.query || '').toLowerCase();
          console.log("Customer Support Query:", q);
          if (q.includes('quên mật khẩu') || q.includes('password') || q.includes('mật khẩu')) {
             followUpText = 'Dạ mình hiểu vấn đề của sếp. Để lấy lại mật khẩu, Sếp có thể bấm vào nút "Quên mật khẩu" ở màn hình Đăng nhập App, sau đó nhập SĐT để nhận mã OTP lấy lại mật khẩu ạ!';
          } else if (q.includes('thanh toán') || q.includes('ví') || q.includes('nạp tiền')) {
             followUpText = 'Về vấn đề thanh toán, hệ thống hỗ trợ Sếp thanh toán bằng Tiền Mặt hoặc Ví điện tử DatnPay. Sếp có thể tự chủ động Nạp tiền vào "Ví của tôi" nằm trong Menu Tài Khoản nha!';
          } else {
             followUpText = `Dạ hệ thống đã tiếp nhận câu hỏi "${call.args.query}" của Sếp. Do thông tin trong Database Support chưa được Admin cập nhật chi tiết cho vấn đề này, Sếp vui lòng liên hệ trực tiếp Tổng Đài 1900-xxxx để được hỗ trợ cụ thể nhé!`;
          }
        } catch (dbError) {
          followUpText = "Xin lỗi Sếp, hệ thống đang bị lỗi không thể kiểm tra dữ liệu khách hàng được.";
        }
      }

      // 2. Return the structured Agent UI Response to Flutter
      return res.json({
        type: uiType,
        text: followUpText,
        data: toolResponseData
      });

    } else {
      // 3. Normal Text Response (Clean up any stray JSON tags)
      let cleanedText = textResponse;
      if (cleanedText.includes('{"tool"')) {
          cleanedText = "Dạ, hệ thống đang tìm cách chạy lệnh nhưng bị lỗi cú pháp xíu xiu. Sếp vui lòng nói lại rõ hơn nhen!";
      }

      console.log(`[AI TEXT]: ${cleanedText}`);
      return res.json({
        type: 'text',
        text: cleanedText.replace(/\{[\s\S]*"tool"[\s\S]*\}/g, '').trim() || textResponse,
      });
    }

  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
});

// Endpoint to send Push Notifications
app.post('/api/notify', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'FCM Token is required' });
    }

    const message = {
      notification: {
        title: title || 'Thông báo mới',
        body: body || 'Bạn có một tin nhắn mới từ Hệ thống.',
      },
      data: data || {},
      token: token,
      android: {
        notification: {
          sound: 'default',
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    if (db) {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      res.status(200).json({ success: true, messageId: response });
    } else {
      res.status(503).json({ error: 'Firebase Admin not initialized properly' });
    }
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Failed to send notification', details: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Agentic Backend Server is running on port ${PORT}`);
});
