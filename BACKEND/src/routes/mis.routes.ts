import { Router } from 'express';
import { getWorkerMis } from '../controllers/mis.controller';
import { authenticateToken } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateToken);
router.get('/worker', getWorkerMis);

export default router;
