import { Response } from 'express';

import { AuthenticatedRequest } from '../middleware/authenticate.js';
import { listApplications, registerApplication } from '../services/applicationService.js';

export const postApplication = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) {
      return res.status(400).json({ message: 'tenantId is required' });
    }

    const app = await registerApplication({
      name: req.body.name,
      redirectUris: req.body.redirectUris,
      tenantId,
    });

    return res.status(201).json(app);
  } catch (error) {
    return res.status(400).json({ message: (error as Error).message });
  }
};

export const getApplications = async (req: AuthenticatedRequest, res: Response) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.status(400).json({ message: 'tenantId is required' });
  }
  const apps = await listApplications(tenantId);
  return res.json(apps);
};
