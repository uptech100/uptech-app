import { Router } from 'express';
import { 
    getAopSummary, 
    getAopMonthly, 
    getAopDrilldown, 
    getAopTransactions, 
    getAopTable 
} from '../controllers/aop.controller';
import { authenticateToken } from '../middlewares/auth.middleware';

const router = Router();

const requireAdmin = (req: any, res: any, next: any) => {
  const user = req.user;
  if (user && user.role === 'Admin') {
    next();
  } else {
    return res.status(403).json({ message: 'Admin access required' });
  }
};

router.use(authenticateToken, requireAdmin);

router.get('/summary', getAopSummary);
router.get('/monthly', getAopMonthly);
router.get('/drilldown', getAopDrilldown);
router.get('/transactions', getAopTransactions);
router.get('/table', getAopTable);
// For backwards compatibility during transition
router.get('/analysis', getAopTable);

export default router;
