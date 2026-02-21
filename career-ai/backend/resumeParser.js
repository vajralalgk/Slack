const fs = require("fs");
const pdfParse = require("pdf-parse");

async function parseResumePDF(filePath) {
  const buffer = fs.readFileSync(filePath);
  const data = await pdfParse(buffer);
  return data.text;
}

function extractSections(text) {
  const sections = {
    summary: "",
    experience: "",
    education: "",
    skills: "",
    certifications: "",
    raw: text,
  };

  const lines = text.split("\n").map((l) => l.trim());
  let currentSection = "summary";

  const sectionMap = {
    experience: ["experience", "work history", "employment"],
    education: ["education", "academic"],
    skills: ["skills", "technical skills", "technologies", "tools"],
    certifications: [
      "certifications",
      "certificates",
      "licenses",
      "credentials",
    ],
    summary: ["summary", "objective", "about", "profile"],
  };

  for (const line of lines) {
    const lower = line.toLowerCase();

    for (const [section, keywords] of Object.entries(sectionMap)) {
      if (keywords.some((kw) => lower.includes(kw) && lower.length < 40)) {
        currentSection = section;
        break;
      }
    }

    sections[currentSection] += line + "\n";
  }

  return sections;
}

module.exports = { parseResumePDF, extractSections };
