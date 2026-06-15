import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth.middleware';
import { 
  importQCItems, 
  getQCItems, 
  addQCItem,
  submitQCReport, 
  getQCReportsHistory 
} from '../controllers/qc.controller';

const router = Router();

// Public/Admin route to import initial seed data
router.post('/import', importQCItems);

// Protected routes for workers/QC staff
router.use(authenticateToken);
router.get('/items', getQCItems);
router.post('/items', addQCItem);
router.post('/report', submitQCReport);
router.get('/report/history', getQCReportsHistory);

export default router;
