const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');
<<<<<<< HEAD
=======
const userRoutes = require('./routes/user.routes');
>>>>>>> a13a053c7e664154f0f7d23c2eded23f055112a7
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
<<<<<<< HEAD
=======
app.use('/api/v1/users', userRoutes);
>>>>>>> a13a053c7e664154f0f7d23c2eded23f055112a7
app.use('/api/v1/debts', debtRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;