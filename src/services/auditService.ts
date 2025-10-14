import { AuditAction } from '@prisma/client';

import prisma from '../utils/prisma.js';

export const logAuditEvent = async (
  params: {
    action: AuditAction;
    metadata: Record<string, unknown>;
    tenantId?: string;
    actorId?: string;
  },
) => {
  const { action, metadata, tenantId, actorId } = params;
  await prisma.auditLog.create({
    data: {
      action,
      metadata,
      tenantId,
      actorId,
    },
  });
};
