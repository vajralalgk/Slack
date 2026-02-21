const express = require("express");
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const { initDatabase } = require("./database");
const jobAnalyzerRoutes = require("./routes/jobAnalyzer");
const resumeMatchRoutes = require("./routes/resumeMatch");
const postGeneratorRoutes = require("./routes/postGenerator");
const profileOptimizerRoutes = require("./routes/profileOptimizer");
const trackerRoutes = require("./routes/tracker");
const settingsRoutes = require("./routes/settings");

const PORT = 3002;

function startBackend() {
  const app = express();

  // Middleware
  app.use(cors());
  app.use(express.json({ limit: "10mb" }));

  // File upload config
  const upload = multer({
    dest: path.join(__dirname, "..", "uploads"),
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
      if (file.mimetype === "application/pdf") {
        cb(null, true);
      } else {
        cb(new Error("Only PDF files are allowed"));
      }
    },
  });

  // Make upload middleware available to routes
  app.locals.upload = upload;

  // Initialize database
  initDatabase();

  // Routes
  app.use("/api/job-analyzer", jobAnalyzerRoutes);
  app.use("/api/resume-match", resumeMatchRoutes);
  app.use("/api/post-generator", postGeneratorRoutes);
  app.use("/api/profile-optimizer", profileOptimizerRoutes);
  app.use("/api/tracker", trackerRoutes);
  app.use("/api/settings", settingsRoutes);

  // Health check
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok" });
  });

  app.listen(PORT, () => {
    console.log(`CareerAI backend running on port ${PORT}`);
  });
}

module.exports = startBackend;
