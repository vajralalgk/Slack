import React, { useState } from "react";
import { Search, Loader2 } from "lucide-react";
import { api } from "../api";

export default function JobAnalyzer() {
  const [jobDescription, setJobDescription] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleAnalyze() {
    if (!jobDescription.trim()) return;
    setLoading(true);
    setError("");
    try {
      const data = await api.analyzeJob(jobDescription);
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-4xl space-y-6">
      <div className="card">
        <h2 className="text-lg font-semibold mb-3">Paste Job Description</h2>
        <textarea
          className="textarea-field h-48"
          placeholder="Paste a LinkedIn job description here..."
          value={jobDescription}
          onChange={(e) => setJobDescription(e.target.value)}
        />
        <button
          className="btn-primary mt-4 flex items-center gap-2"
          onClick={handleAnalyze}
          disabled={loading || !jobDescription.trim()}
        >
          {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Search className="w-4 h-4" />}
          {loading ? "Analyzing..." : "Analyze Job"}
        </button>
        {error && <p className="text-red-400 mt-3 text-sm">{error}</p>}
      </div>

      {result && (
        <div className="space-y-4">
          <div className="card">
            <h3 className="font-semibold text-accent mb-2">{result.title || "Job Analysis"}</h3>
            {result.company && <p className="text-dark-300 text-sm mb-3">Company: {result.company}</p>}
            <div className="flex gap-3 mb-4">
              <span className="px-3 py-1 bg-accent/20 text-accent rounded-full text-xs font-medium">
                {result.seniority?.toUpperCase()} LEVEL
              </span>
              {result.remotePolicy && (
                <span className="px-3 py-1 bg-dark-700 text-dark-200 rounded-full text-xs font-medium">
                  {result.remotePolicy}
                </span>
              )}
              {result.yearsExperience && (
                <span className="px-3 py-1 bg-dark-700 text-dark-200 rounded-full text-xs font-medium">
                  {result.yearsExperience}
                </span>
              )}
            </div>
          </div>

          <div className="card">
            <h3 className="font-semibold mb-3">Required Skills</h3>
            <div className="flex flex-wrap gap-2">
              {result.requiredSkills?.map((s, i) => (
                <span
                  key={i}
                  className={`px-3 py-1 rounded-full text-xs font-medium ${
                    s.category === "core"
                      ? "bg-red-500/20 text-red-300"
                      : s.category === "preferred"
                      ? "bg-yellow-500/20 text-yellow-300"
                      : "bg-green-500/20 text-green-300"
                  }`}
                >
                  {s.skill}
                </span>
              ))}
            </div>
          </div>

          {result.keyResponsibilities?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3">Key Responsibilities</h3>
              <ul className="space-y-2">
                {result.keyResponsibilities.map((r, i) => (
                  <li key={i} className="text-dark-300 text-sm flex gap-2">
                    <span className="text-accent">•</span> {r}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {result.toolsAndTech?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3">Tools & Technologies</h3>
              <div className="flex flex-wrap gap-2">
                {result.toolsAndTech.map((t, i) => (
                  <span key={i} className="px-3 py-1 bg-dark-700 text-dark-200 rounded-full text-xs">
                    {t}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
