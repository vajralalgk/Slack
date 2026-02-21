const express = require("express");
const router = express.Router();
const { parseResumePDF, extractSections } = require("../resumeParser");
const { scoreResume } = require("../scoringEngine");
const { chatJSON, chat } = require("../aiService");
const fs = require("fs");

router.post("/upload", (req, res) => {
  const upload = req.app.locals.upload;
  upload.single("resume")(req, res, async (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }

    try {
      const text = await parseResumePDF(req.file.path);
      const sections = extractSections(text);

      // Clean up temp file
      fs.unlinkSync(req.file.path);

      res.json({ text, sections });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
});

router.post("/score", async (req, res) => {
  try {
    const { resumeText, jobRequirements } = req.body;

    if (!resumeText || !jobRequirements) {
      return res.status(400).json({ error: "Resume text and job requirements are required" });
    }

    // Extract skills from resume using AI
    const systemPrompt = `Extract all technical skills, tools, and technologies from this resume.
Return JSON: {"skills": ["skill1", "skill2", ...]}`;

    const extracted = await chatJSON(systemPrompt, resumeText);
    const result = scoreResume(extracted.skills, jobRequirements);

    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post("/suggestions", async (req, res) => {
  try {
    const { resumeText, missingSkills, jobDescription } = req.body;

    const systemPrompt = `You are a resume improvement expert. Given a resume, a job description, and missing skills,
suggest specific bullet point rewrites and additions to improve the match.
Return JSON:
{
  "bulletRewrites": [{"original": "...", "improved": "...", "reason": "..."}],
  "newBullets": [{"bullet": "...", "section": "experience|skills|summary"}],
  "generalTips": ["tip1", "tip2"]
}`;

    const userMsg = `Resume:\n${resumeText}\n\nJob Description:\n${jobDescription}\n\nMissing Skills: ${missingSkills.join(", ")}`;
    const suggestions = await chatJSON(systemPrompt, userMsg);

    res.json(suggestions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
