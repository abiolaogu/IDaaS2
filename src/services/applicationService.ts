import crypto from 'crypto';
import { Application, AuditAction } from '@prisma/client';
import { z } from 'zod';

import prisma from '../utils/prisma.js';
import { logAuditEvent } from './auditService.js';

const applicationSchema = z.object({
  name: z.string().min(3),
  redirectUris: z.array(z.string().url()).min(1),
  tenantId: z.string().uuid(),
});

export type ApplicationInput = z.infer<typeof applicationSchema>;

export const registerApplication = async (payload: ApplicationInput): Promise<Application> => {
  const data = applicationSchema.parse(payload);
  const clientId = crypto.randomBytes(16).toString('hex');
  const clientSecret = crypto.randomBytes(32).toString('hex');

  const app = await prisma.application.create({
    data: {
      name: data.name,
      redirectUris: data.redirectUris,
      tenantId: data.tenantId,
      clientId,
      clientSecret,
    },
  });

  await logAuditEvent({
    action: AuditAction.APPLICATION_REGISTERED,
    tenantId: data.tenantId,
    metadata: { applicationId: app.id, name: app.name },
  });

  return app;
};

export const listApplications = async (tenantId: string): Promise<Application[]> =>
  prisma.application.findMany({ where: { tenantId } });
