import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { AuditAction } from '@prisma/client';
import { z } from 'zod';

import config from '../config.js';
import prisma from '../utils/prisma.js';
import { logAuditEvent } from './auditService.js';
import { findUserByEmail } from './userService.js';

const authSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  tenantSlug: z.string(),
});

export type AuthenticateInput = z.infer<typeof authSchema>;

export const authenticateUser = async (payload: AuthenticateInput) => {
  const data = authSchema.parse(payload);
  const tenant = await prisma.tenant.findUnique({ where: { slug: data.tenantSlug } });
  if (!tenant) {
    throw new Error('Tenant not found');
  }

  const user = await findUserByEmail(tenant.id, data.email);
  if (!user) {
    throw new Error('Invalid credentials');
  }

  const isPasswordValid = await bcrypt.compare(data.password, user.password);
  if (!isPasswordValid) {
    throw new Error('Invalid credentials');
  }

  const token = jwt.sign(
    {
      sub: user.id,
      tenantId: user.tenantId,
      roles: user.roles,
    },
    config.jwtSecret,
    {
      expiresIn: '1h',
      issuer: 'idaas-saas-platform',
    },
  );

  await logAuditEvent({
    action: AuditAction.USER_AUTHENTICATED,
    actorId: user.id,
    tenantId: user.tenantId,
    metadata: { email: user.email },
  });

  await logAuditEvent({
    action: AuditAction.TOKEN_ISSUED,
    actorId: user.id,
    tenantId: user.tenantId,
    metadata: { tokenType: 'access', expiresIn: '1h' },
  });

  return { token, user, tenant };
};
