import React, { useState } from "react";
import { User, Loader2 } from "lucide-react";
import { api } from "../api";

export default function ProfileOptimizer() {
  const [headline, setHeadline] = useState("");
  const [about, setAbout] = useState("");
  const [experience, setExperience] = useState("");
  const [targetRole, setTargetRole] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleAnalyze() {
    if (!headline && !about && !experience) return;
    setLoading(true);
    setError("");
    try {
      const data = await api.analyzeProfile(headline, about, experience, targetRole);
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function ScoreBar({ label, score }) {
    const color = score >= 70 ? "bg-green-500" : score >= 40 ? "bg-yellow-500" : "bg-red-500";
    return (
      <div className="mb-3">
        <div className="flex justify-between text-sm mb-1">
          <span className="text-dark-300">{label}</span>
          <span className="text-dark-200 font-medium">{score}/100</span>
        </div>
        <div className="w-full bg-dark-700 rounded-full h-2">
          <div className={`${color} h-2 rounded-full transition-all`} style={{ width: `${score}%` }} />
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl space-y-6">
      <div className="card">
        <h2 className="text-lg font-semibold mb-3">Your LinkedIn Profile</h2>
        <input
          className="input-field mb-3"
          placeholder="Target Role (e.g., Senior ML Engineer)"
          value={targetRole}
          onChange={(e) => setTargetRole(e.target.value)}
        />
        <input
          className="input-field mb-3"
          placeholder="Current Headline"
          value={headline}
          onChange={(e) => setHeadline(e.target.value)}
        />
        <textarea
          className="textarea-field h-28 mb-3"
          placeholder="About / Summary section"
          value={about}
          onChange={(e) => setAbout(e.target.value)}
        />
        <textarea
          className="textarea-field h-28 mb-4"
          placeholder="Experience (paste your current role description)"
          value={experience}
          onChange={(e) => setExperience(e.target.value)}
        />
        <button
          className="btn-primary flex items-center gap-2"
          onClick={handleAnalyze}
          disabled={loading || (!headline && !about && !experience)}
        >
          {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <User className="w-4 h-4" />}
          {loading ? "Analyzing..." : "Analyze Profile"}
        </button>
        {error && <p className="text-red-400 mt-3 text-sm">{error}</p>}
      </div>

      {result && (
        <div className="space-y-4">
          <div className="card">
            <h3 className="font-semibold mb-4">Profile Scores</h3>
            <ScoreBar label="Overall" score={result.overallScore} />
            <ScoreBar label="Headline" score={result.headlineScore} />
            <ScoreBar label="About Section" score={result.aboutScore} />
            {result.positioningClarity && (
              <p className="text-sm text-dark-400 mt-2">
                Positioning: <span className={`font-medium ${result.positioningClarity === "clear" ? "text-green-400" : "text-yellow-400"}`}>
                  {result.positioningClarity}
                </span>
              </p>
            )}
          </div>

          {result.suggestedHeadline && (
            <div className="card">
              <h3 className="font-semibold mb-2">Suggested Headline</h3>
              <p className="text-accent text-sm bg-accent/10 p-3 rounded-lg">{result.suggestedHeadline}</p>
            </div>
          )}

          {result.suggestedAbout && (
            <div className="card">
              <h3 className="font-semibold mb-2">Suggested About</h3>
              <p className="text-dark-200 text-sm bg-dark-900 p-3 rounded-lg whitespace-pre-wrap">{result.suggestedAbout}</p>
            </div>
          )}

          {result.keywordsMissing?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-2">Missing Keywords</h3>
              <div className="flex flex-wrap gap-2">
                {result.keywordsMissing.map((kw, i) => (
                  <span key={i} className="px-3 py-1 bg-red-500/20 text-red-300 rounded-full text-xs">{kw}</span>
                ))}
              </div>
            </div>
          )}

          {result.topRecommendations?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-2">Top Recommendations</h3>
              {result.topRecommendations.map((rec, i) => (
                <p key={i} className="text-sm text-dark-300 mb-1">• {rec}</p>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
