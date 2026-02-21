const express = require("express");
const router = express.Router();
const { chat } = require("../aiService");

router.post("/generate", async (req, res) => {
  try {
    const { topic, depth, tone, style } = req.body;

    if (!topic) {
      return res.status(400).json({ error: "Topic is required" });
    }

    const depthLabel = depth || "intermediate";
    const toneLabel = tone || "professional";
    const styleLabel = style || "informative";

    const systemPrompt = `You are a LinkedIn technical content writer. Write a LinkedIn post about the given topic.

Requirements:
- Depth: ${depthLabel} (beginner/intermediate/advanced/expert)
- Tone: ${toneLabel} (professional/casual/opinionated/storytelling)
- Style: ${styleLabel} (informative/tutorial/opinion/case-study)

Structure:
1. Hook (1-2 compelling opening lines)
2. Body (main insight with real-world context)
3. A concrete example or data point
4. Closing question to drive engagement
5. 3-5 relevant hashtags

Keep it under 300 words. No fluff. Make it sound like an experienced engineer sharing real insights.`;

    const post = await chat(systemPrompt, `Write a post about: ${topic}`);

    res.json({ post });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post("/refine", async (req, res) => {
  try {
    const { post, instruction } = req.body;

    if (!post || !instruction) {
      return res.status(400).json({ error: "Post and instruction are required" });
    }

    const systemPrompt = `You are a LinkedIn content editor. Refine the given post based on the instruction.
Keep the same structure but apply the requested changes. Return only the refined post.`;

    const refined = await chat(
      systemPrompt,
      `Original post:\n${post}\n\nInstruction: ${instruction}`
    );

    res.json({ post: refined });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
