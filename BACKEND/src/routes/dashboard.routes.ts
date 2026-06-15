import { Router } from 'express';
import { getDashboardData } from '../controllers/dashboard.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { auditLog } from '../middlewares/audit.middleware';

const router = Router();

router.get('/', authenticateToken, auditLog, getDashboardData);

export default router;
