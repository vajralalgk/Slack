const express = require("express");
const router = express.Router();
const { chatJSON } = require("../aiService");

router.post("/analyze", async (req, res) => {
  try {
    const { headline, about, experience, targetRole } = req.body;

    if (!headline && !about && !experience) {
      return res.status(400).json({ error: "At least one profile section is required" });
    }

    const systemPrompt = `You are a LinkedIn profile optimization expert. Analyze the profile sections and provide improvements.

Target role: ${targetRole || "not specified"}

Return JSON:
{
  "headlineScore": 0-100,
  "headlineIssues": ["issue1"],
  "suggestedHeadline": "improved headline",
  "aboutScore": 0-100,
  "aboutIssues": ["issue1"],
  "suggestedAbout": "improved about section",
  "keywordsMissing": ["keyword1", "keyword2"],
  "positioningClarity": "clear|vague|misaligned",
  "overallScore": 0-100,
  "topRecommendations": ["rec1", "rec2", "rec3"]
}`;

    const profileText = [
      headline ? `Headline: ${headline}` : "",
      about ? `About: ${about}` : "",
      experience ? `Experience: ${experience}` : "",
    ]
      .filter(Boolean)
      .join("\n\n");

    const analysis = await chatJSON(systemPrompt, profileText);

    res.json(analysis);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
