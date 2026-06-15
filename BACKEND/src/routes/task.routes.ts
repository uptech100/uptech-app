import { Router } from 'express';
import { getTodaysTasks, getAllTasks, createTask, markTaskComplete, getUsers, getTasksAssignedByMe, reopenTask } from '../controllers/task.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { auditLog } from '../middlewares/audit.middleware';

const router = Router();

router.use(authenticateToken);
router.use(auditLog);

router.get('/users', getUsers);
router.get('/today', getTodaysTasks);
router.get('/assigned-by-me', getTasksAssignedByMe);
router.get('/all', getAllTasks);
router.post('/', createTask);
router.put('/:taskId/complete', markTaskComplete);
router.post('/:taskId/reopen', reopenTask);

export default router;
