const express = require('express');
const cors = require('cors');
<<<<<<< HEAD
const apiRouter = require('./routes');
=======
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const debtRoutes = require('./routes/debt.routes'); 
const transactionRoutes = require('./routes/transaction.routes');
const settingsRoutes = require('./routes/settings.routes');

>>>>>>> 9f5909d5ffab0a7c07304ed16c57780b578c4a77
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

<<<<<<< HEAD
app.use('/api/v1', apiRouter);
=======
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
app.use('/api/v1/settings', settingsRoutes);
>>>>>>> 9f5909d5ffab0a7c07304ed16c57780b578c4a77

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;