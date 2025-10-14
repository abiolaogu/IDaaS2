import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : undefined;
dotenv.config(envFile ? { path: envFile } : undefined);

const prisma = new PrismaClient();

export default prisma;
