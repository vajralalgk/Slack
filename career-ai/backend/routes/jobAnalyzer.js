const express = require("express");
const router = express.Router();
const { chatJSON } = require("../aiService");
const { detectSeniority } = require("../scoringEngine");

router.post("/analyze", async (req, res) => {
  try {
    const { jobDescription } = req.body;

    if (!jobDescription) {
      return res.status(400).json({ error: "Job description is required" });
    }

    const systemPrompt = `You are a job description analyzer. Extract structured data from the job description.
Return a JSON object with these fields:
{
  "title": "job title",
  "company": "company name if mentioned",
  "requiredSkills": [{"skill": "name", "category": "core|preferred|nice_to_have"}],
  "yearsExperience": "extracted years requirement",
  "education": "education requirement",
  "domain": "industry/domain focus",
  "leadershipSignals": ["list of leadership/management indicators"],
  "remotePolicy": "remote/hybrid/onsite/unknown",
  "keyResponsibilities": ["top 5 responsibilities"],
  "toolsAndTech": ["specific tools and technologies mentioned"]
}`;

    const analysis = await chatJSON(systemPrompt, jobDescription);
    const seniority = detectSeniority(jobDescription);

    res.json({
      ...analysis,
      seniority,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
