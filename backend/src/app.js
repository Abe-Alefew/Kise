const express = require('express');
const cors = require('cors');
const apiRouter = require('./routes/');
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

app.use('/api/v1', apiRouter);
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
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/debts', debtRoutes);
app.use('/api/v1/transactions', transactionRoutes);


app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;