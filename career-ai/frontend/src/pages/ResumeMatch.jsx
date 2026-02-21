import React, { useState } from "react";
import { Upload, FileText, Loader2, BarChart3 } from "lucide-react";
import { api } from "../api";

export default function ResumeMatch() {
  const [resumeText, setResumeText] = useState("");
  const [jobDescription, setJobDescription] = useState("");
  const [score, setScore] = useState(null);
  const [suggestions, setSuggestions] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleFileUpload(e) {
    const file = e.target.files[0];
    if (!file) return;
    setLoading(true);
    setError("");
    try {
      const data = await api.uploadResume(file);
      setResumeText(data.text);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleScore() {
    if (!resumeText.trim() || !jobDescription.trim()) return;
    setLoading(true);
    setError("");
    try {
      const jobAnalysis = await api.analyzeJob(jobDescription);
      const scoreResult = await api.scoreResume(resumeText, jobAnalysis.requiredSkills || []);
      setScore(scoreResult);

      if (scoreResult.missing?.length > 0) {
        const sugg = await api.getResumeSuggestions(
          resumeText,
          scoreResult.missing.map((m) => m.skill),
          jobDescription
        );
        setSuggestions(sugg);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-4xl space-y-6">
      <div className="grid grid-cols-2 gap-6">
        <div className="card">
          <h2 className="text-lg font-semibold mb-3">Resume</h2>
          <label className="btn-secondary flex items-center gap-2 w-fit cursor-pointer mb-3">
            <Upload className="w-4 h-4" />
            Upload PDF
            <input type="file" accept=".pdf" className="hidden" onChange={handleFileUpload} />
          </label>
          <textarea
            className="textarea-field h-40"
            placeholder="Or paste resume text here..."
            value={resumeText}
            onChange={(e) => setResumeText(e.target.value)}
          />
        </div>

        <div className="card">
          <h2 className="text-lg font-semibold mb-3">Job Description</h2>
          <textarea
            className="textarea-field h-52"
            placeholder="Paste the target job description..."
            value={jobDescription}
            onChange={(e) => setJobDescription(e.target.value)}
          />
        </div>
      </div>

      <button
        className="btn-primary flex items-center gap-2"
        onClick={handleScore}
        disabled={loading || !resumeText.trim() || !jobDescription.trim()}
      >
        {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <BarChart3 className="w-4 h-4" />}
        {loading ? "Scoring..." : "Score Match"}
      </button>
      {error && <p className="text-red-400 text-sm">{error}</p>}

      {score && (
        <div className="space-y-4">
          <div className="card text-center">
            <p className="text-sm text-dark-400 mb-2">Match Score</p>
            <p className={`text-5xl font-bold ${score.score >= 70 ? "text-green-400" : score.score >= 40 ? "text-yellow-400" : "text-red-400"}`}>
              {score.score}%
            </p>
            <p className="text-dark-400 text-sm mt-2">
              {score.matchedCount} of {score.totalSkills} skills matched
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="card">
              <h3 className="font-semibold text-green-400 mb-2">Matched Skills</h3>
              <div className="space-y-1">
                {score.matched?.map((s, i) => (
                  <p key={i} className="text-sm text-dark-300">+ {s.skill}</p>
                ))}
              </div>
            </div>
            <div className="card">
              <h3 className="font-semibold text-red-400 mb-2">Missing Skills</h3>
              <div className="space-y-1">
                {score.missing?.map((s, i) => (
                  <p key={i} className="text-sm text-dark-300">- {s.skill}</p>
                ))}
              </div>
            </div>
          </div>

          {suggestions && (
            <div className="card">
              <h3 className="font-semibold mb-3">Improvement Suggestions</h3>
              {suggestions.generalTips?.map((tip, i) => (
                <p key={i} className="text-sm text-dark-300 mb-1">• {tip}</p>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
