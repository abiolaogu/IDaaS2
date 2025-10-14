import { Router } from 'express';

import { postAuthenticate } from '../controllers/authController.js';
import { getApplications, postApplication } from '../controllers/applicationController.js';
import { getTenants, postTenant } from '../controllers/tenantController.js';
import { getUsers, postUser } from '../controllers/userController.js';
import { authenticate, requireRole } from '../middleware/authenticate.js';

const router = Router();

router.post('/auth/token', postAuthenticate);
router.post('/tenants', postTenant);
router.get('/tenants', getTenants);

router.post('/users', authenticate, requireRole(['admin']), postUser);
router.get('/users', authenticate, requireRole(['admin']), getUsers);

router.post('/applications', authenticate, requireRole(['admin']), postApplication);
router.get('/applications', authenticate, requireRole(['admin']), getApplications);

export default router;
