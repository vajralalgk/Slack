const API_BASE = "/api";

async function request(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const config = {
    headers: { "Content-Type": "application/json" },
    ...options,
  };

  if (config.body && typeof config.body === "object" && !(config.body instanceof FormData)) {
    config.body = JSON.stringify(config.body);
  }

  if (config.body instanceof FormData) {
    delete config.headers["Content-Type"];
  }

  const res = await fetch(url, config);
  const data = await res.json();

  if (!res.ok) {
    throw new Error(data.error || "Request failed");
  }

  return data;
}

export const api = {
  // Job Analyzer
  analyzeJob: (jobDescription) =>
    request("/job-analyzer/analyze", {
      method: "POST",
      body: { jobDescription },
    }),

  // Resume Match
  uploadResume: (file) => {
    const formData = new FormData();
    formData.append("resume", file);
    return request("/resume-match/upload", {
      method: "POST",
      body: formData,
    });
  },
  scoreResume: (resumeText, jobRequirements) =>
    request("/resume-match/score", {
      method: "POST",
      body: { resumeText, jobRequirements },
    }),
  getResumeSuggestions: (resumeText, missingSkills, jobDescription) =>
    request("/resume-match/suggestions", {
      method: "POST",
      body: { resumeText, missingSkills, jobDescription },
    }),

  // Post Generator
  generatePost: (topic, depth, tone, style) =>
    request("/post-generator/generate", {
      method: "POST",
      body: { topic, depth, tone, style },
    }),
  refinePost: (post, instruction) =>
    request("/post-generator/refine", {
      method: "POST",
      body: { post, instruction },
    }),

  // Profile Optimizer
  analyzeProfile: (headline, about, experience, targetRole) =>
    request("/profile-optimizer/analyze", {
      method: "POST",
      body: { headline, about, experience, targetRole },
    }),

  // Application Tracker
  getApplications: () => request("/tracker/applications"),
  addApplication: (data) =>
    request("/tracker/applications", { method: "POST", body: data }),
  updateApplication: (id, data) =>
    request(`/tracker/applications/${id}`, { method: "PUT", body: data }),
  deleteApplication: (id) =>
    request(`/tracker/applications/${id}`, { method: "DELETE" }),
  getStats: () => request("/tracker/stats"),

  // Settings
  getSettings: () => request("/settings"),
  setApiKey: (apiKey) =>
    request("/settings/api-key", { method: "POST", body: { apiKey } }),
  setModel: (model) =>
    request("/settings/model", { method: "POST", body: { model } }),
  deleteApiKey: () => request("/settings/api-key", { method: "DELETE" }),
};
