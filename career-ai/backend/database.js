const Database = require("better-sqlite3");
const path = require("path");

let db;

function getDbPath() {
  return path.join(__dirname, "..", "database", "career.db");
}

function initDatabase() {
  db = new Database(getDbPath());

  // Enable WAL mode for better concurrent performance
  db.pragma("journal_mode = WAL");

  db.exec(`
    CREATE TABLE IF NOT EXISTS applications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company TEXT NOT NULL,
      role TEXT NOT NULL,
      url TEXT,
      applied_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'applied',
      salary_range TEXT,
      location TEXT,
      notes TEXT,
      follow_up_date TEXT,
      match_score INTEGER,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS application_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      application_id INTEGER NOT NULL,
      event_type TEXT NOT NULL,
      description TEXT,
      event_date TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
    );
  `);

  return db;
}

function getDb() {
  if (!db) {
    initDatabase();
  }
  return db;
}

module.exports = { initDatabase, getDb };
