import request from 'supertest';

import app from '../src/app.js';
import prisma from '../src/utils/prisma.js';
import { createUser } from '../src/services/userService.js';

describe('IDaaS SaaS platform API', () => {
  it('creates tenant, authenticates admin, manages users and applications', async () => {
    const tenantResponse = await request(app)
      .post('/api/tenants')
      .send({ name: 'Acme Corp', slug: 'acme' })
      .expect(201);

    const tenantId = tenantResponse.body.id as string;

    await createUser({
      email: 'admin@acme.com',
      password: 'Secur3P@ssword',
      displayName: 'Acme Admin',
      roles: ['admin'],
      tenantId,
    });

    const authResponse = await request(app)
      .post('/api/auth/token')
      .send({
        email: 'admin@acme.com',
        password: 'Secur3P@ssword',
        tenantSlug: 'acme',
      })
      .expect(200);

    const token = authResponse.body.token as string;

    const userResponse = await request(app)
      .post('/api/users')
      .set('Authorization', `Bearer ${token}`)
      .send({
        email: 'user@acme.com',
        password: 'AnotherS3cret',
        displayName: 'Acme User',
        roles: ['user'],
      })
      .expect(201);

    expect(userResponse.body.email).toBe('user@acme.com');

    const listUsers = await request(app)
      .get('/api/users')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(listUsers.body).toHaveLength(2);

    const appResponse = await request(app)
      .post('/api/applications')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Acme Dashboard',
        redirectUris: ['https://dashboard.acme.com/callback'],
      })
      .expect(201);

    expect(appResponse.body.clientId).toBeDefined();

    const listApps = await request(app)
      .get('/api/applications')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(listApps.body).toHaveLength(1);

    const auditCount = await prisma.auditLog.count();
    expect(auditCount).toBeGreaterThanOrEqual(4);
  });
});
