const OpenAI = require("openai");
const Store = require("electron-store");

const store = new Store();

function getClient() {
  const apiKey = store.get("openai-api-key");
  if (!apiKey) {
    throw new Error("OpenAI API key not configured. Go to Settings to add it.");
  }
  return new OpenAI({ apiKey });
}

async function chat(systemPrompt, userMessage, options = {}) {
  const client = getClient();
  const model = store.get("ai-model", "gpt-4o-mini");

  const response = await client.chat.completions.create({
    model,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    temperature: options.temperature ?? 0.7,
    max_tokens: options.maxTokens ?? 2000,
  });

  return response.choices[0].message.content;
}

async function chatJSON(systemPrompt, userMessage, options = {}) {
  const client = getClient();
  const model = store.get("ai-model", "gpt-4o-mini");

  const response = await client.chat.completions.create({
    model,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    temperature: options.temperature ?? 0.3,
    max_tokens: options.maxTokens ?? 2000,
    response_format: { type: "json_object" },
  });

  return JSON.parse(response.choices[0].message.content);
}

module.exports = { chat, chatJSON };
