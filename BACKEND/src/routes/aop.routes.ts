import { Router } from 'express';
import { getAopAnalysis } from '../controllers/aop.controller';
import { authenticateToken } from '../middlewares/auth.middleware';

const router = Router();

// Only admin should view AOP Analysis
router.get('/analysis', authenticateToken, (req, res, next) => {
  const user = (req as any).user;
  if (user && user.role === 'Admin') {
    next();
  } else {
    return res.status(403).json({ message: 'Admin access required' });
  }
}, getAopAnalysis);

export default router;
