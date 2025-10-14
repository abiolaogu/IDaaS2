import { Tenant } from '@prisma/client';
import { z } from 'zod';

import prisma from '../utils/prisma.js';

const tenantSchema = z.object({
  name: z.string().min(3),
  slug: z
    .string()
    .regex(/^[a-z0-9-]+$/, 'Slug must be URL friendly (lowercase letters, numbers, hyphen).'),
});

export type TenantInput = z.infer<typeof tenantSchema>;

export const createTenant = async (payload: TenantInput): Promise<Tenant> => {
  const data = tenantSchema.parse(payload);
  return prisma.tenant.create({
    data,
  });
};

export const listTenants = async (): Promise<Tenant[]> => prisma.tenant.findMany();
