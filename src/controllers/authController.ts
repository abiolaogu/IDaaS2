import { Request, Response } from 'express';

import { authenticateUser } from '../services/authService.js';

export const postAuthenticate = async (req: Request, res: Response) => {
  try {
    const { token, user, tenant } = await authenticateUser(req.body);
    return res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        roles: user.roles,
      },
      tenant: {
        id: tenant.id,
        name: tenant.name,
        slug: tenant.slug,
      },
    });
  } catch (error) {
    return res.status(401).json({ message: (error as Error).message });
  }
};
