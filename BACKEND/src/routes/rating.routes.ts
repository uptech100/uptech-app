import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth.middleware';
import { getUsersToRate, submitRating, getAdminRatingsSummary } from '../controllers/rating.controller';

const router = Router();

router.use(authenticateToken);

// User routes
router.get('/users', getUsersToRate);
router.post('/', submitRating);

// Admin routes
router.get('/admin-summary', getAdminRatingsSummary);

export default router;
