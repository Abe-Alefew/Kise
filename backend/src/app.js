const express = require('express');
const cors = require('cors');
const apiRouter = require('./routes');
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

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;