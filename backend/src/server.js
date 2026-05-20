const app = require('./app');
const config = require('./config');
const database = require('./config/database');

async function startServer() {
  await database.initialize();

  const server = app.listen(config.port, () => {
    console.log(`Kise API listening on port ${config.port}`);
  });

  const shutdown = async (signal) => {
    console.log(`Received ${signal}. Shutting down...`);
    server.close(async () => {
      await database.close();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});