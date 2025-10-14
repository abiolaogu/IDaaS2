import express from 'express';
import morgan from 'morgan';

import router from './routes/index.js';

const app = express();

app.use(express.json());
app.use(morgan('dev'));
app.use('/api', router);

app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok' });
});

export default app;
