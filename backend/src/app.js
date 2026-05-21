const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');
const debtRoutes = require('./routes/debt.routes'); 

const { notFoundHandler, errorHandler } = require('./middleware/error.middleware');

const app = express();

const corsOptions = {
  origin: process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim())
    : true,
  credentials: true,
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

app.get('/api/v1/health', (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      timestamp: new Date().toISOString(),
    },
  });
});

app.use('/api/v1/auth', authRoutes);
// app.use('/api/v1/debts', debtRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;