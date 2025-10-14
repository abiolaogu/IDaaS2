import { Request, Response } from 'express';

import { createTenant, listTenants } from '../services/tenantService.js';

export const postTenant = async (req: Request, res: Response) => {
  try {
    const tenant = await createTenant(req.body);
    return res.status(201).json(tenant);
  } catch (error) {
    return res.status(400).json({ message: (error as Error).message });
  }
};

export const getTenants = async (_req: Request, res: Response) => {
  const tenants = await listTenants();
  return res.json(tenants);
};
