import React, { useState, useEffect } from "react";
import { Plus, Trash2, Edit3, X, Check } from "lucide-react";
import { api } from "../api";

const STATUS_COLORS = {
  applied: "bg-blue-500/20 text-blue-300",
  screening: "bg-yellow-500/20 text-yellow-300",
  interviewing: "bg-purple-500/20 text-purple-300",
  offer: "bg-green-500/20 text-green-300",
  rejected: "bg-red-500/20 text-red-300",
  withdrawn: "bg-dark-500/20 text-dark-300",
};

const STATUSES = ["applied", "screening", "interviewing", "offer", "rejected", "withdrawn"];

export default function Tracker() {
  const [apps, setApps] = useState([]);
  const [stats, setStats] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({ company: "", role: "", url: "", applied_date: "", status: "applied", location: "", notes: "" });
  const [error, setError] = useState("");

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      const [appData, statsData] = await Promise.all([api.getApplications(), api.getStats()]);
      setApps(appData);
      setStats(statsData);
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleSubmit() {
    if (!form.company || !form.role || !form.applied_date) return;
    try {
      if (editingId) {
        await api.updateApplication(editingId, form);
      } else {
        await api.addApplication(form);
      }
      setForm({ company: "", role: "", url: "", applied_date: "", status: "applied", location: "", notes: "" });
      setShowForm(false);
      setEditingId(null);
      loadData();
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleDelete(id) {
    try {
      await api.deleteApplication(id);
      loadData();
    } catch (err) {
      setError(err.message);
    }
  }

  function startEdit(app) {
    setForm({ company: app.company, role: app.role, url: app.url || "", applied_date: app.applied_date, status: app.status, location: app.location || "", notes: app.notes || "" });
    setEditingId(app.id);
    setShowForm(true);
  }

  return (
    <div className="max-w-5xl space-y-6">
      {stats && (
        <div className="grid grid-cols-4 gap-4">
          <div className="card text-center">
            <p className="text-3xl font-bold text-accent">{stats.total}</p>
            <p className="text-sm text-dark-400">Total</p>
          </div>
          <div className="card text-center">
            <p className="text-3xl font-bold text-blue-400">{stats.byStatus?.applied || 0}</p>
            <p className="text-sm text-dark-400">Applied</p>
          </div>
          <div className="card text-center">
            <p className="text-3xl font-bold text-purple-400">{stats.byStatus?.interviewing || 0}</p>
            <p className="text-sm text-dark-400">Interviewing</p>
          </div>
          <div className="card text-center">
            <p className="text-3xl font-bold text-green-400">{stats.byStatus?.offer || 0}</p>
            <p className="text-sm text-dark-400">Offers</p>
          </div>
        </div>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-lg font-semibold">Applications</h2>
        <button className="btn-primary flex items-center gap-2" onClick={() => { setShowForm(!showForm); setEditingId(null); setForm({ company: "", role: "", url: "", applied_date: "", status: "applied", location: "", notes: "" }); }}>
          {showForm ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {showForm ? "Cancel" : "Add Application"}
        </button>
      </div>
      {error && <p className="text-red-400 text-sm">{error}</p>}

      {showForm && (
        <div className="card space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <input className="input-field" placeholder="Company *" value={form.company} onChange={(e) => setForm({ ...form, company: e.target.value })} />
            <input className="input-field" placeholder="Role *" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} />
            <input className="input-field" type="date" value={form.applied_date} onChange={(e) => setForm({ ...form, applied_date: e.target.value })} />
            <select className="input-field" value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
              {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
            <input className="input-field" placeholder="Location" value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} />
            <input className="input-field" placeholder="Job URL" value={form.url} onChange={(e) => setForm({ ...form, url: e.target.value })} />
          </div>
          <textarea className="textarea-field h-20" placeholder="Notes" value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
          <button className="btn-primary flex items-center gap-2" onClick={handleSubmit}>
            <Check className="w-4 h-4" /> {editingId ? "Update" : "Save"}
          </button>
        </div>
      )}

      <div className="space-y-2">
        {apps.map((app) => (
          <div key={app.id} className="card flex items-center justify-between py-4">
            <div className="flex-1">
              <div className="flex items-center gap-3">
                <h3 className="font-medium text-white">{app.company}</h3>
                <span className={`px-2 py-0.5 rounded-full text-xs ${STATUS_COLORS[app.status] || STATUS_COLORS.applied}`}>{app.status}</span>
              </div>
              <p className="text-sm text-dark-400">{app.role} {app.location ? `· ${app.location}` : ""}</p>
              <p className="text-xs text-dark-500 mt-1">{app.applied_date}</p>
            </div>
            <div className="flex gap-2">
              <button onClick={() => startEdit(app)} className="p-2 hover:bg-dark-700 rounded-lg transition-colors"><Edit3 className="w-4 h-4 text-dark-400" /></button>
              <button onClick={() => handleDelete(app.id)} className="p-2 hover:bg-dark-700 rounded-lg transition-colors"><Trash2 className="w-4 h-4 text-red-400" /></button>
            </div>
          </div>
        ))}
        {apps.length === 0 && (
          <p className="text-dark-500 text-center py-8">No applications yet. Click "Add Application" to start tracking.</p>
        )}
      </div>
    </div>
  );
}
