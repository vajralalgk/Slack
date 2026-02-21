import React, { useState } from "react";
import Sidebar from "./components/Sidebar";
import JobAnalyzer from "./pages/JobAnalyzer";
import ResumeMatch from "./pages/ResumeMatch";
import PostGenerator from "./pages/PostGenerator";
import ProfileOptimizer from "./pages/ProfileOptimizer";
import Tracker from "./pages/Tracker";
import Settings from "./pages/Settings";

const PAGES = {
  jobAnalyzer: { component: JobAnalyzer, label: "Job Analyzer" },
  resumeMatch: { component: ResumeMatch, label: "Resume Match" },
  postGenerator: { component: PostGenerator, label: "Post Generator" },
  profileOptimizer: { component: ProfileOptimizer, label: "Profile Optimizer" },
  tracker: { component: Tracker, label: "Tracker" },
  settings: { component: Settings, label: "Settings" },
};

export default function App() {
  const [activePage, setActivePage] = useState("jobAnalyzer");
  const PageComponent = PAGES[activePage].component;

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar activePage={activePage} onNavigate={setActivePage} />
      <main className="flex-1 overflow-y-auto p-8">
        <h1 className="text-2xl font-bold mb-6">{PAGES[activePage].label}</h1>
        <PageComponent />
      </main>
    </div>
  );
}
