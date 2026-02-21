import React from "react";
import {
  Search,
  FileText,
  PenTool,
  User,
  LayoutDashboard,
  Settings,
  Sparkles,
} from "lucide-react";

const NAV_ITEMS = [
  { id: "jobAnalyzer", label: "Job Analyzer", icon: Search },
  { id: "resumeMatch", label: "Resume Match", icon: FileText },
  { id: "postGenerator", label: "Post Generator", icon: PenTool },
  { id: "profileOptimizer", label: "Profile Optimizer", icon: User },
  { id: "tracker", label: "Tracker", icon: LayoutDashboard },
];

export default function Sidebar({ activePage, onNavigate }) {
  return (
    <aside className="w-64 bg-dark-800 border-r border-dark-700 flex flex-col h-full">
      {/* Logo */}
      <div className="p-6 border-b border-dark-700">
        <div className="flex items-center gap-2">
          <Sparkles className="w-6 h-6 text-accent" />
          <span className="text-lg font-bold text-white">CareerAI</span>
        </div>
        <p className="text-xs text-dark-400 mt-1">AI Career Intelligence</p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1">
        {NAV_ITEMS.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => onNavigate(id)}
            className={
              activePage === id ? "sidebar-link-active w-full" : "sidebar-link w-full"
            }
          >
            <Icon className="w-5 h-5" />
            <span className="text-sm font-medium">{label}</span>
          </button>
        ))}
      </nav>

      {/* Settings at bottom */}
      <div className="p-4 border-t border-dark-700">
        <button
          onClick={() => onNavigate("settings")}
          className={
            activePage === "settings"
              ? "sidebar-link-active w-full"
              : "sidebar-link w-full"
          }
        >
          <Settings className="w-5 h-5" />
          <span className="text-sm font-medium">Settings</span>
        </button>
      </div>
    </aside>
  );
}
