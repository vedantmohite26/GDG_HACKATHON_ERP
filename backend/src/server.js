require("dotenv").config();
require("express-async-errors");
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");

// Import routes
const authRoutes = require("./routes/auth");
const certificateRoutes = require("./routes/certificates");
const resultRoutes = require("./routes/results");

// Import database
const { sequelize } = require("./models");

const app = express();
const PORT = process.env.PORT || 5000;

// Security middleware
app.use(helmet());
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS?.split(",") || "*",
    credentials: true,
  }),
);

// Logging middleware
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
} else {
  app.use(morgan("combined"));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: "Too many requests from this IP, please try again later.",
});
app.use("/api/", limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/certificates", certificateRoutes);
app.use("/api/results", resultRoutes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: { message: "Endpoint not found" } });
});

// Refined Centralized Error handler
app.use((err, req, res, next) => {
  const status = err.status || 500;
  const message = err.message || "Internal server error";

  // Log everything in dev, only critical in prod
  if (process.env.NODE_ENV === "development" || status >= 500) {
    console.error(`[Error] ${req.method} ${req.url}:`, err.stack);
  }

  res.status(status).json({
    error: {
      message,
      ...(process.env.NODE_ENV === "development" && { 
        stack: err.stack,
        details: err.details || null 
      }),
    },
  });
});

// Database sync and server start
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log("✅ Database connection established successfully.");

    // Sync database (creates tables if they don't exist)
    await sequelize.sync({ alter: process.env.NODE_ENV === "development" });
    console.log("✅ Database synchronized.");

    app.listen(PORT, () => {
      console.log(`✅ Server running on port ${PORT}`);
      console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error("❌ Unable to start server:", error);
    process.exit(1);
  }
};

startServer();

module.exports = app;
