import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth.middleware';
import { auditLog } from '../middlewares/audit.middleware';
import {
  createChecklistTemplate,
  getAdminChecklists,
  getMyChecklists,
  markChecklistComplete,
  getChecklistHistory,
} from '../controllers/checklist.controller';

const router = Router();

router.use(authenticateToken);

// Admin Routes (Could add role middleware here if needed)
router.post('/templates', auditLog, createChecklistTemplate);
router.get('/templates', getAdminChecklists);

// Worker Routes
router.get('/my-logs', getMyChecklists);
router.post('/logs', markChecklistComplete);
router.get('/history', getChecklistHistory);

export default router;
