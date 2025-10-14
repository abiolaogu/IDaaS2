import app from './app.js';
import config from './config.js';

const server = app.listen(config.port, () => {
  // eslint-disable-next-line no-console
  console.log(`IDaaS platform API listening on port ${config.port}`);
});

process.on('SIGTERM', () => {
  server.close(() => {
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  server.close(() => {
    process.exit(0);
  });
});
