const express = require("express");
const router = express.Router();
const { getDb } = require("../database");

// Get all applications
router.get("/applications", (req, res) => {
  try {
    const db = getDb();
    const apps = db
      .prepare("SELECT * FROM applications ORDER BY applied_date DESC")
      .all();
    res.json(apps);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add new application
router.post("/applications", (req, res) => {
  try {
    const db = getDb();
    const {
      company,
      role,
      url,
      applied_date,
      status,
      salary_range,
      location,
      notes,
      follow_up_date,
      match_score,
    } = req.body;

    if (!company || !role || !applied_date) {
      return res
        .status(400)
        .json({ error: "Company, role, and applied date are required" });
    }

    const stmt = db.prepare(`
      INSERT INTO applications (company, role, url, applied_date, status, salary_range, location, notes, follow_up_date, match_score)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      company,
      role,
      url || null,
      applied_date,
      status || "applied",
      salary_range || null,
      location || null,
      notes || null,
      follow_up_date || null,
      match_score || null
    );

    res.json({ id: result.lastInsertRowid });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update application
router.put("/applications/:id", (req, res) => {
  try {
    const db = getDb();
    const { id } = req.params;
    const fields = req.body;

    const allowed = [
      "company",
      "role",
      "url",
      "applied_date",
      "status",
      "salary_range",
      "location",
      "notes",
      "follow_up_date",
      "match_score",
    ];

    const updates = [];
    const values = [];

    for (const [key, value] of Object.entries(fields)) {
      if (allowed.includes(key)) {
        updates.push(`${key} = ?`);
        values.push(value);
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No valid fields to update" });
    }

    updates.push("updated_at = datetime('now')");
    values.push(id);

    db.prepare(
      `UPDATE applications SET ${updates.join(", ")} WHERE id = ?`
    ).run(...values);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete application
router.delete("/applications/:id", (req, res) => {
  try {
    const db = getDb();
    db.prepare("DELETE FROM applications WHERE id = ?").run(req.params.id);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Dashboard stats
router.get("/stats", (req, res) => {
  try {
    const db = getDb();

    const total = db
      .prepare("SELECT COUNT(*) as count FROM applications")
      .get().count;
    const byStatus = db
      .prepare(
        "SELECT status, COUNT(*) as count FROM applications GROUP BY status"
      )
      .all();
    const avgScore = db
      .prepare(
        "SELECT AVG(match_score) as avg FROM applications WHERE match_score IS NOT NULL"
      )
      .get().avg;
    const recentApps = db
      .prepare(
        "SELECT * FROM applications ORDER BY applied_date DESC LIMIT 5"
      )
      .all();

    res.json({
      total,
      byStatus: Object.fromEntries(byStatus.map((s) => [s.status, s.count])),
      averageMatchScore: avgScore ? Math.round(avgScore) : null,
      recentApplications: recentApps,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
