const express = require("express");
const router = express.Router();
const Store = require("electron-store");

const store = new Store();

router.get("/", (req, res) => {
  res.json({
    hasApiKey: !!store.get("openai-api-key"),
    model: store.get("ai-model", "gpt-4o-mini"),
  });
});

router.post("/api-key", (req, res) => {
  const { apiKey } = req.body;

  if (!apiKey) {
    return res.status(400).json({ error: "API key is required" });
  }

  store.set("openai-api-key", apiKey);
  res.json({ success: true });
});

router.post("/model", (req, res) => {
  const { model } = req.body;
  const allowed = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"];

  if (!allowed.includes(model)) {
    return res.status(400).json({ error: `Model must be one of: ${allowed.join(", ")}` });
  }

  store.set("ai-model", model);
  res.json({ success: true });
});

router.delete("/api-key", (req, res) => {
  store.delete("openai-api-key");
  res.json({ success: true });
});

module.exports = router;
