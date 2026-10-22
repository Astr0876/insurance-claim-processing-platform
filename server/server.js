const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from server/.env explicitly
dotenv.config({ path: path.join(__dirname, '.env') });
dotenv.config();

const { connectDb, getDriver } = require('./config/db');

// Import routes
const authRoutes = require('./routes/authRoutes');
const claimRoutes = require('./routes/claimRoutes');
const documentRoutes = require('./routes/documentRoutes');
const fraudRoutes = require('./routes/fraudRoutes');
const reportRoutes = require('./routes/reportRoutes');
const userRoutes = require('./routes/userRoutes');
const policyRoutes = require('./routes/policyRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const auditRoutes = require('./routes/auditRoutes');
const settingsRoutes = require('./routes/settingsRoutes');

const app = express();
const PORT = process.env.PORT || 5001;

// Middleware
app.use(cors({
  origin: true,
  credentials: true
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// Static uploads folder
const uploadsPath = path.join(__dirname, 'uploads');
app.use('/uploads', express.static(uploadsPath));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ONLINE',
    service: 'Insurance Claim Processing & Fraud Detection Platform API',
    databaseDriver: getDriver(),
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/claims', claimRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/fraud', fraudRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/users', userRoutes);
app.use('/api/policies', policyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/audit-logs', auditRoutes);
app.use('/api/settings', settingsRoutes);

// 404 Route Handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `API endpoint not found: ${req.method} ${req.originalUrl}`
  });
});

// Centralized Error Handler
app.use((err, req, res, next) => {
  console.error('[Server Error]', err.stack || err.message);

  const statusCode = err.status || (res.statusCode !== 200 ? res.statusCode : 500);
  res.status(statusCode).json({
    success: false,
    message: err.message || 'An unexpected internal server error occurred.',
    errorType: err.name || 'ServerError'
  });
});

// Start Server
async function startServer() {
  try {
    await connectDb();
    app.listen(PORT, () => {
      console.log(`====================================================`);
      console.log(`🚀 Insurance Claim Processing & Fraud Detection API`);
      console.log(`   Running on: http://localhost:${PORT}`);
      console.log(`   Database Driver: ${getDriver().toUpperCase()}`);
      console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`====================================================`);
    });
  } catch (error) {
    console.error('Fatal: Failed to bootstrap server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
