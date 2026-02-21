/**
 * Resume-to-Job scoring engine.
 *
 * Compares extracted resume skills against job requirements
 * and produces a weighted match score.
 */

const SKILL_WEIGHTS = {
  core: 3,
  preferred: 2,
  nice_to_have: 1,
};

function normalizeSkill(skill) {
  return skill.toLowerCase().trim().replace(/[^a-z0-9+#. ]/g, "");
}

function scoreResume(resumeSkills, jobRequirements) {
  const normalizedResume = resumeSkills.map(normalizeSkill);

  let totalWeight = 0;
  let matchedWeight = 0;
  const matched = [];
  const missing = [];

  for (const req of jobRequirements) {
    const skill = normalizeSkill(req.skill);
    const weight = SKILL_WEIGHTS[req.category] || 1;
    totalWeight += weight;

    const isMatch = normalizedResume.some(
      (rs) => rs.includes(skill) || skill.includes(rs)
    );

    if (isMatch) {
      matchedWeight += weight;
      matched.push({ skill: req.skill, category: req.category, weight });
    } else {
      missing.push({ skill: req.skill, category: req.category, weight });
    }
  }

  const score = totalWeight > 0 ? Math.round((matchedWeight / totalWeight) * 100) : 0;

  return {
    score,
    matched,
    missing,
    totalSkills: jobRequirements.length,
    matchedCount: matched.length,
    missingCount: missing.length,
  };
}

function detectSeniority(jobText) {
  const lower = jobText.toLowerCase();

  const signals = {
    principal: ["principal", "staff engineer", "distinguished", "fellow"],
    senior: [
      "senior",
      "sr.",
      "lead",
      "5+ years",
      "7+ years",
      "10+ years",
      "architect",
    ],
    mid: ["mid-level", "mid level", "3+ years", "2+ years", "intermediate"],
    junior: ["junior", "jr.", "entry level", "entry-level", "0-2 years", "new grad"],
  };

  for (const [level, keywords] of Object.entries(signals)) {
    if (keywords.some((kw) => lower.includes(kw))) {
      return level;
    }
  }

  return "mid";
}

module.exports = { scoreResume, detectSeniority, normalizeSkill };
