import dotenv from 'dotenv';

const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : undefined;
dotenv.config(envFile ? { path: envFile } : undefined);

const config = {
  port: Number(process.env.PORT ?? 3000),
  jwtSecret: process.env.JWT_SECRET ?? 'insecure-default',
};

if (!process.env.JWT_SECRET) {
  // eslint-disable-next-line no-console
  console.warn('JWT_SECRET is not set. Using insecure default. Do not use in production.');
}

export default config;
