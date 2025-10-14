import { Response } from 'express';

import { AuthenticatedRequest } from '../middleware/authenticate.js';
import { createUser, listUsers } from '../services/userService.js';

export const postUser = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const tenantId = req.user?.tenantId ?? req.body.tenantId;
    if (!tenantId) {
      return res.status(400).json({ message: 'tenantId is required' });
    }

    const user = await createUser({
      email: req.body.email,
      password: req.body.password,
      displayName: req.body.displayName,
      roles: req.body.roles,
      tenantId,
    });

    return res.status(201).json({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      roles: user.roles,
      tenantId: user.tenantId,
    });
  } catch (error) {
    return res.status(400).json({ message: (error as Error).message });
  }
};

export const getUsers = async (req: AuthenticatedRequest, res: Response) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.status(400).json({ message: 'tenantId is required' });
  }
  const users = await listUsers(tenantId);
  return res.json(
    users.map((user) => ({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      roles: user.roles,
      tenantId: user.tenantId,
      createdAt: user.createdAt,
    })),
  );
};
