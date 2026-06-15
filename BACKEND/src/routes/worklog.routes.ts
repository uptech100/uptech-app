import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth.middleware';
import {
  getTodayLog,
  addWorkEntry,
  updateWorkEntry,
  finalizeLog,
  getWorkHistory,
  getWorkerOptions,
} from '../controllers/worklog.controller';

const router = Router();

router.use(authenticateToken);

router.get('/today', getTodayLog);
router.post('/entry', addWorkEntry);
router.put('/entry/:id', updateWorkEntry);
router.post('/finalize', finalizeLog);
router.get('/history', getWorkHistory);
router.get('/options', getWorkerOptions);

export default router;
