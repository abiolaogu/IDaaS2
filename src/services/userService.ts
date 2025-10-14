import bcrypt from 'bcryptjs';
import { AuditAction, User } from '@prisma/client';
import { z } from 'zod';

import prisma from '../utils/prisma.js';
import { logAuditEvent } from './auditService.js';

const userSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(2),
  roles: z.array(z.string()).default(['user']),
  tenantId: z.string().uuid(),
});

export type UserInput = z.infer<typeof userSchema>;

export const createUser = async (payload: UserInput): Promise<User> => {
  const data = userSchema.parse(payload);
  const hashedPassword = await bcrypt.hash(data.password, 10);
  const user = await prisma.user.create({
    data: {
      email: data.email,
      password: hashedPassword,
      displayName: data.displayName,
      tenantId: data.tenantId,
      roles: data.roles,
    },
  });

  await logAuditEvent({
    action: AuditAction.USER_CREATED,
    tenantId: user.tenantId,
    actorId: user.id,
    metadata: { email: user.email },
  });

  return user;
};

export const findUserByEmail = async (
  tenantId: string,
  email: string,
): Promise<User | null> =>
  prisma.user.findFirst({
    where: { tenantId, email },
  });

export const listUsers = async (tenantId: string): Promise<User[]> =>
  prisma.user.findMany({ where: { tenantId }, orderBy: { createdAt: 'desc' } });
