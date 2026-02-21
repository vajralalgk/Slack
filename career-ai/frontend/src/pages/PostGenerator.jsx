import React, { useState } from "react";
import { PenTool, Loader2, RefreshCw, Copy, Check } from "lucide-react";
import { api } from "../api";

export default function PostGenerator() {
  const [topic, setTopic] = useState("");
  const [depth, setDepth] = useState("intermediate");
  const [tone, setTone] = useState("professional");
  const [style, setStyle] = useState("informative");
  const [post, setPost] = useState("");
  const [refineInput, setRefineInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState("");

  async function handleGenerate() {
    if (!topic.trim()) return;
    setLoading(true);
    setError("");
    try {
      const data = await api.generatePost(topic, depth, tone, style);
      setPost(data.post);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleRefine() {
    if (!post || !refineInput.trim()) return;
    setLoading(true);
    setError("");
    try {
      const data = await api.refinePost(post, refineInput);
      setPost(data.post);
      setRefineInput("");
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function handleCopy() {
    navigator.clipboard.writeText(post);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div className="max-w-4xl space-y-6">
      <div className="card">
        <h2 className="text-lg font-semibold mb-3">Generate LinkedIn Post</h2>
        <input
          className="input-field mb-4"
          placeholder="Topic (e.g., LLM inference optimization, GPU memory management)"
          value={topic}
          onChange={(e) => setTopic(e.target.value)}
        />
        <div className="grid grid-cols-3 gap-4 mb-4">
          <div>
            <label className="text-sm text-dark-400 mb-1 block">Depth</label>
            <select className="input-field" value={depth} onChange={(e) => setDepth(e.target.value)}>
              <option value="beginner">Beginner</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
              <option value="expert">Expert</option>
            </select>
          </div>
          <div>
            <label className="text-sm text-dark-400 mb-1 block">Tone</label>
            <select className="input-field" value={tone} onChange={(e) => setTone(e.target.value)}>
              <option value="professional">Professional</option>
              <option value="casual">Casual</option>
              <option value="opinionated">Opinionated</option>
              <option value="storytelling">Storytelling</option>
            </select>
          </div>
          <div>
            <label className="text-sm text-dark-400 mb-1 block">Style</label>
            <select className="input-field" value={style} onChange={(e) => setStyle(e.target.value)}>
              <option value="informative">Informative</option>
              <option value="tutorial">Tutorial</option>
              <option value="opinion">Opinion</option>
              <option value="case-study">Case Study</option>
            </select>
          </div>
        </div>
        <button
          className="btn-primary flex items-center gap-2"
          onClick={handleGenerate}
          disabled={loading || !topic.trim()}
        >
          {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <PenTool className="w-4 h-4" />}
          {loading ? "Generating..." : "Generate Post"}
        </button>
        {error && <p className="text-red-400 mt-3 text-sm">{error}</p>}
      </div>

      {post && (
        <div className="card">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-semibold">Generated Post</h3>
            <button onClick={handleCopy} className="btn-secondary flex items-center gap-2 text-sm py-1.5 px-3">
              {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
              {copied ? "Copied!" : "Copy"}
            </button>
          </div>
          <div className="bg-dark-900 rounded-lg p-4 whitespace-pre-wrap text-sm text-dark-200 leading-relaxed">
            {post}
          </div>

          <div className="mt-4 flex gap-2">
            <input
              className="input-field flex-1"
              placeholder="Refine: 'Make it more technical' or 'Add a personal story'"
              value={refineInput}
              onChange={(e) => setRefineInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleRefine()}
            />
            <button
              className="btn-secondary flex items-center gap-2"
              onClick={handleRefine}
              disabled={loading || !refineInput.trim()}
            >
              <RefreshCw className="w-4 h-4" />
              Refine
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
