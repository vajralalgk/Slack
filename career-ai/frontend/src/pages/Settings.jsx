import React, { useState, useEffect } from "react";
import { Save, Trash2, Key, Cpu } from "lucide-react";
import { api } from "../api";

export default function Settings() {
  const [apiKey, setApiKey] = useState("");
  const [model, setModel] = useState("gpt-4o-mini");
  const [hasKey, setHasKey] = useState(false);
  const [saved, setSaved] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    api.getSettings().then((data) => {
      setHasKey(data.hasApiKey);
      setModel(data.model);
    }).catch(() => {});
  }, []);

  async function handleSaveKey() {
    if (!apiKey.trim()) return;
    try {
      await api.setApiKey(apiKey);
      setHasKey(true);
      setApiKey("");
      setSaved("API key saved successfully");
      setTimeout(() => setSaved(""), 3000);
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleDeleteKey() {
    try {
      await api.deleteApiKey();
      setHasKey(false);
      setSaved("API key removed");
      setTimeout(() => setSaved(""), 3000);
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleSaveModel() {
    try {
      await api.setModel(model);
      setSaved("Model preference saved");
      setTimeout(() => setSaved(""), 3000);
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="max-w-2xl space-y-6">
      <div className="card">
        <div className="flex items-center gap-2 mb-4">
          <Key className="w-5 h-5 text-accent" />
          <h2 className="text-lg font-semibold">OpenAI API Key</h2>
        </div>
        <p className="text-sm text-dark-400 mb-3">
          Required for AI features. Get your key from{" "}
          <span className="text-accent">platform.openai.com</span>
        </p>
        {hasKey && (
          <div className="flex items-center gap-2 mb-3 bg-green-500/10 text-green-400 px-3 py-2 rounded-lg text-sm">
            API key is configured
            <button onClick={handleDeleteKey} className="ml-auto text-red-400 hover:text-red-300">
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        )}
        <div className="flex gap-2">
          <input
            type="password"
            className="input-field flex-1"
            placeholder={hasKey ? "Enter new key to replace..." : "sk-..."}
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
          />
          <button className="btn-primary flex items-center gap-2" onClick={handleSaveKey} disabled={!apiKey.trim()}>
            <Save className="w-4 h-4" /> Save
          </button>
        </div>
      </div>

      <div className="card">
        <div className="flex items-center gap-2 mb-4">
          <Cpu className="w-5 h-5 text-accent" />
          <h2 className="text-lg font-semibold">AI Model</h2>
        </div>
        <select className="input-field mb-3" value={model} onChange={(e) => setModel(e.target.value)}>
          <option value="gpt-4o">GPT-4o (Best quality)</option>
          <option value="gpt-4o-mini">GPT-4o Mini (Fast & affordable)</option>
          <option value="gpt-4-turbo">GPT-4 Turbo</option>
          <option value="gpt-3.5-turbo">GPT-3.5 Turbo (Fastest)</option>
        </select>
        <button className="btn-primary flex items-center gap-2" onClick={handleSaveModel}>
          <Save className="w-4 h-4" /> Save Model
        </button>
      </div>

      {saved && <p className="text-green-400 text-sm">{saved}</p>}
      {error && <p className="text-red-400 text-sm">{error}</p>}

      <div className="card">
        <h2 className="text-lg font-semibold mb-2">About CareerAI</h2>
        <p className="text-sm text-dark-400">
          AI Career Intelligence System v1.0.0
        </p>
        <p className="text-sm text-dark-500 mt-1">
          Desktop application for job analysis, resume scoring, LinkedIn post generation, and career tracking.
        </p>
      </div>
    </div>
  );
}
