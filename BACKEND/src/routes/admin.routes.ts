import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth.middleware';
import { auditLog } from '../middlewares/audit.middleware';
import {
  getDepartments, createDepartment, updateDepartment, deleteDepartment,
  getRoles, createRole, updateRole, deleteRole,
  getUsers, createUser, updateUser, deleteUser, resetUserPassword,
  getProcesses, createProcess, updateProcess, deleteProcess,
  getProducts, createProduct, updateProduct, deleteProduct,
} from '../controllers/admin.controller';

const router = Router();

// All admin routes require authentication
router.use(authenticateToken);
router.use(auditLog);

// Admin role check middleware
router.use((req, res, next) => {
  const user = (req as any).user;
  console.log('[Admin Route Check] User:', user);
  const role = user?.role;
  if (role !== 'Admin') {
    console.log('[Admin Route Check] Access denied. Role is', role);
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
});

// Department routes
router.get('/departments', getDepartments);
router.post('/departments', createDepartment);
router.put('/departments/:id', updateDepartment);
router.delete('/departments/:id', deleteDepartment);

// Role routes
router.get('/roles', getRoles);
router.post('/roles', createRole);
router.put('/roles/:id', updateRole);
router.delete('/roles/:id', deleteRole);

// User routes
router.get('/users', getUsers);
router.post('/users', createUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.post('/users/:id/reset-password', resetUserPassword);

// Process routes
router.get('/processes', getProcesses);
router.post('/processes', createProcess);
router.put('/processes/:id', updateProcess);
router.delete('/processes/:id', deleteProcess);

// Product routes
router.get('/products', getProducts);
router.post('/products', createProduct);
router.put('/products/:id', updateProduct);
router.delete('/products/:id', deleteProduct);

export default router;
