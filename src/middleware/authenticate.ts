import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

import config from '../config.js';
import prisma from '../utils/prisma.js';

type AuthTokenPayload = {
  sub: string;
  tenantId: string;
  roles: string[];
};

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    tenantId: string;
    roles: string[];
  };
}

export const authenticate = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: 'Authorization header missing' });
    }

    const [, token] = authHeader.split(' ');
    if (!token) {
      return res.status(401).json({ message: 'Bearer token missing' });
    }

    const payload = jwt.verify(token, config.jwtSecret) as AuthTokenPayload;
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || user.tenantId !== payload.tenantId) {
      return res.status(401).json({ message: 'Invalid token subject' });
    }

    req.user = {
      id: user.id,
      tenantId: user.tenantId,
      roles: payload.roles,
    };

    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
};

export const requireRole = (roles: string[]) => (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) => {
  const userRoles = req.user?.roles ?? [];
  const hasRole = roles.some((role) => userRoles.includes(role));
  if (!hasRole) {
    return res.status(403).json({ message: 'Forbidden' });
  }
  return next();
};
