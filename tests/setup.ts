import { execSync } from 'child_process';
import type { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

process.env.NODE_ENV = 'test';
dotenv.config({ path: '.env.test', override: true });

let prisma: PrismaClient;

beforeAll(async () => {
  const module = await import('../src/utils/prisma.js');
  prisma = module.default;
  execSync('npx prisma migrate deploy', { stdio: 'inherit' });
});

afterEach(async () => {
  await prisma.auditLog.deleteMany();
  await prisma.application.deleteMany();
  await prisma.user.deleteMany();
  await prisma.tenant.deleteMany();
});

afterAll(async () => {
  await prisma.$disconnect();
});
