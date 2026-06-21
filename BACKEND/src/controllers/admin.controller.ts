import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

// ─── DEPARTMENTS ────────────────────────────────────────────

export const getDepartments = async (req: Request, res: Response) => {
  try {
    const departments = await prisma.department.findMany({
      include: { _count: { select: { users: true } } },
      orderBy: { name: 'asc' },
    });
    res.json(departments);
  } catch (error) {
    console.error('Error fetching departments:', error);
    res.status(500).json({ message: 'Failed to fetch departments' });
  }
};

export const createDepartment = async (req: Request, res: Response) => {
  try {
    const { name, departmentCode, description, status } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Department name is required' });
    }
    const department = await prisma.department.create({
      data: { 
        name: name.trim(),
        departmentCode: departmentCode?.trim(),
        description: description?.trim(),
        status: status || 'Active',
      },
    });
    res.status(201).json(department);
  } catch (error: any) {
    if (error.code === 'P2002') {
      return res.status(409).json({ message: 'Department already exists' });
    }
    console.error('Error creating department:', error);
    res.status(500).json({ message: 'Failed to create department' });
  }
};

export const updateDepartment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, departmentCode, description, status } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Department name is required' });
    }
    
    const updateData: any = { name: name.trim() };
    if (departmentCode !== undefined) updateData.departmentCode = departmentCode?.trim();
    if (description !== undefined) updateData.description = description?.trim();
    if (status !== undefined) updateData.status = status;

    const department = await prisma.department.update({
      where: { id: Number(id) },
      data: updateData,
    });
    res.json(department);
  } catch (error: any) {
    if (error.code === 'P2002') {
      return res.status(409).json({ message: 'Department already exists' });
    }
    console.error('Error updating department:', error);
    res.status(500).json({ message: 'Failed to update department' });
  }
};

export const deleteDepartment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    // Check if department has users
    const userCount = await prisma.user.count({ where: { departmentId: Number(id) } });
    if (userCount > 0) {
      return res.status(400).json({ message: 'Cannot delete department with assigned users. Remove or reassign users first.' });
    }

    // Check if department has checklist templates
    const checklistCount = await prisma.checklistTemplate.count({ where: { departmentId: Number(id) } });
    if (checklistCount > 0) {
      return res.status(400).json({ message: 'Cannot delete department with assigned checklist templates. Remove checklists first.' });
    }

    await prisma.department.delete({ where: { id: Number(id) } });
    res.json({ message: 'Department deleted successfully' });
  } catch (error) {
    console.error('Error deleting department:', error);
    res.status(500).json({ message: 'Failed to delete department' });
  }
};

// ─── ROLES ──────────────────────────────────────────────────

export const getRoles = async (req: Request, res: Response) => {
  try {
    const roles = await prisma.role.findMany({ orderBy: { name: 'asc' } });
    res.json(roles);
  } catch (error) {
    console.error('Error fetching roles:', error);
    res.status(500).json({ message: 'Failed to fetch roles' });
  }
};

export const createRole = async (req: Request, res: Response) => {
  try {
    const { name, permissions } = req.body;
    if (!name) return res.status(400).json({ message: 'Role name is required' });

    const role = await prisma.role.create({
      data: {
        name: name.trim(),
        permissions: permissions || {},
      },
    });
    res.status(201).json(role);
  } catch (error: any) {
    console.error('Error creating role:', error);
    if (error.code === 'P2002') return res.status(400).json({ message: 'Role already exists' });
    res.status(500).json({ message: 'Failed to create role' });
  }
};

export const updateRole = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, permissions } = req.body;

    const role = await prisma.role.update({
      where: { id: Number(id) },
      data: {
        name: name?.trim(),
        permissions: permissions || undefined,
      },
    });
    res.json(role);
  } catch (error: any) {
    console.error('Error updating role:', error);
    if (error.code === 'P2002') return res.status(400).json({ message: 'Role name already exists' });
    res.status(500).json({ message: 'Failed to update role' });
  }
};

export const deleteRole = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const roleId = Number(id);

    // Prevent deleting roles if users are assigned
    const usersCount = await prisma.user.count({ where: { roleId } });
    if (usersCount > 0) {
      return res.status(400).json({ message: `Cannot delete role. ${usersCount} user(s) are assigned to it.` });
    }

    await prisma.role.delete({ where: { id: roleId } });
    res.json({ message: 'Role deleted successfully' });
  } catch (error) {
    console.error('Error deleting role:', error);
    res.status(500).json({ message: 'Failed to delete role' });
  }
};

// ─── USERS ──────────────────────────────────────────────────

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        employeeId: true,
        name: true,
        mobile: true,
        email: true,
        status: true,
        roleId: true,
        role: { select: { id: true, name: true } },
        departmentId: true,
        department: { select: { id: true, name: true } },
        createdAt: true,
      },
      orderBy: { name: 'asc' },
    });
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Failed to fetch users' });
  }
};

export const createUser = async (req: Request, res: Response) => {
  try {
    const { employeeId, name, mobile, email, password, roleId, departmentId, status } = req.body;

    if (!employeeId || !name || !password || !roleId || !departmentId) {
      return res.status(400).json({ message: 'All fields are required: employeeId, name, password, roleId, departmentId' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        employeeId: employeeId.trim(),
        name: name.trim(),
        mobile: (mobile && mobile.trim() !== '') ? mobile.trim() : `MOB-${Date.now()}`,
        email: (email && email.trim() !== '') ? email.trim() : null,
        passwordHash,
        roleId: Number(roleId),
        departmentId: Number(departmentId),
        status: status || 'Active',
      },
      include: { role: true, department: true },
    });

    res.status(201).json({
      id: user.id,
      employeeId: user.employeeId,
      name: user.name,
      mobile: user.mobile,
      email: user.email,
      status: user.status,
      role: user.role,
      department: user.department,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      const field = error.meta?.target?.[0] || 'field';
      return res.status(409).json({ message: `A user with this ${field} already exists` });
    }
    console.error('Error creating user:', error);
    res.status(500).json({ message: 'Failed to create user' });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { employeeId, name, mobile, email, password, roleId, departmentId, status } = req.body;

    const updateData: any = {};
    if (employeeId) updateData.employeeId = employeeId.trim();
    if (name) updateData.name = name.trim();
    if (mobile !== undefined) updateData.mobile = (mobile && mobile.trim() !== '') ? mobile.trim() : `MOB-${Date.now()}`;
    if (email !== undefined) updateData.email = (email && email.trim() !== '') ? email.trim() : null;
    if (password) updateData.passwordHash = await bcrypt.hash(password, 10);
    if (roleId) updateData.roleId = Number(roleId);
    if (departmentId) updateData.departmentId = Number(departmentId);
    if (status) updateData.status = status;

    const user = await prisma.user.update({
      where: { id: Number(id) },
      data: updateData,
      include: { role: true, department: true },
    });

    res.json({
      id: user.id,
      employeeId: user.employeeId,
      name: user.name,
      mobile: user.mobile,
      email: user.email,
      status: user.status,
      role: user.role,
      department: user.department,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      const field = error.meta?.target?.[0] || 'field';
      return res.status(409).json({ message: `A user with this ${field} already exists` });
    }
    console.error('Error updating user:', error);
    res.status(500).json({ message: 'Failed to update user' });
  }
};

export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = Number(id);

    // Don't allow deleting yourself
    const requestingUserId = (req as any).user?.userId;
    if (userId === requestingUserId) {
      return res.status(400).json({ message: 'You cannot delete your own account' });
    }

    // Delete related records first
    await prisma.notification.deleteMany({ where: { userId } });
    await prisma.attendance.deleteMany({ where: { userId } });
    await prisma.leaveRequest.deleteMany({ where: { userId } });
    await prisma.delegation.deleteMany({ where: { userId } });
    await prisma.payroll.deleteMany({ where: { userId } });
    await prisma.announcement.deleteMany({ where: { authorId: userId } });
    await prisma.task.deleteMany({ where: { OR: [{ assignedToId: userId }, { createdById: userId }] } });

    // Handle DailyWorkLog and WorkEntry
    const dailyLogs = await prisma.dailyWorkLog.findMany({ where: { userId }, select: { id: true } });
    if (dailyLogs.length > 0) {
      await prisma.workEntry.deleteMany({ where: { dailyLogId: { in: dailyLogs.map(l => l.id) } } });
      await prisma.dailyWorkLog.deleteMany({ where: { userId } });
    }

    // Handle QCDailyLog and QCReportEntry
    const qcLogs = await prisma.qCDailyLog.findMany({ where: { userId }, select: { id: true } });
    if (qcLogs.length > 0) {
      await prisma.qCReportEntry.deleteMany({ where: { qcLogId: { in: qcLogs.map(l => l.id) } } });
      await prisma.qCDailyLog.deleteMany({ where: { userId } });
    }

    // Handle Checklists
    await prisma.checklistLog.deleteMany({ where: { userId } });
    const templates = await prisma.checklistTemplate.findMany({ where: { userId }, select: { id: true } });
    if (templates.length > 0) {
      await prisma.checklistLog.deleteMany({ where: { templateId: { in: templates.map(t => t.id) } } });
      await prisma.checklistTemplate.deleteMany({ where: { userId } });
    }

    await prisma.user.delete({ where: { id: userId } });
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Failed to delete user' });
  }
};
export const resetUserPassword = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ message: 'New password is required' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await prisma.user.update({
      where: { id: Number(id) },
      data: { passwordHash },
    });

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({ message: 'Failed to reset password' });
  }
};

// --- Work Process Routes ---
export const getProcesses = async (req: Request, res: Response) => {
  try {
    const processes = await prisma.workProcess.findMany({ orderBy: { id: 'asc' } });
    res.json(processes);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const createProcess = async (req: Request, res: Response) => {
  try {
    const { name, status } = req.body;
    if (!name) return res.status(400).json({ message: 'Name is required' });

    const process = await prisma.workProcess.create({
      data: { name: name.trim(), status: status || 'Active' }
    });
    res.status(201).json(process);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateProcess = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, status } = req.body;
    const process = await prisma.workProcess.update({
      where: { id: Number(id) },
      data: { name: name?.trim(), status }
    });
    res.json(process);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteProcess = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await prisma.workProcess.delete({ where: { id: Number(id) } });
    res.json({ message: 'Process deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

// --- Work Product Routes ---
export const getProducts = async (req: Request, res: Response) => {
  try {
    const products = await prisma.workProduct.findMany({ orderBy: { id: 'asc' } });
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const createProduct = async (req: Request, res: Response) => {
  try {
    const { name, status } = req.body;
    if (!name) return res.status(400).json({ message: 'Name is required' });

    const product = await prisma.workProduct.create({
      data: { name: name.trim(), status: status || 'Active' }
    });
    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, status } = req.body;
    const product = await prisma.workProduct.update({
      where: { id: Number(id) },
      data: { name: name?.trim(), status }
    });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await prisma.workProduct.delete({ where: { id: Number(id) } });
    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
};

// --- MIS Reports Route ---
export const getMisReports = async (req: Request, res: Response) => {
  try {
    const { startDate, endDate } = req.query;
    
    if (!startDate || !endDate) {
      return res.status(400).json({ message: 'startDate and endDate are required' });
    }

    const start = new Date(startDate as string);
    const end = new Date(endDate as string);

    // End date should include the full day
    end.setUTCHours(23, 59, 59, 999);

    const users = await prisma.user.findMany({
      where: { status: 'Active' },
      select: {
        id: true,
        name: true,
        employeeId: true,
        department: { select: { name: true } },
        role: { select: { name: true } }
      }
    });

    const userIds = users.map(u => u.id);

    // Fetch Tasks
    const tasks = await prisma.task.findMany({
      where: {
        assignedToId: { in: userIds },
        createdAt: {
          gte: start,
          lte: end
        }
      },
      select: {
        assignedToId: true,
        status: true
      }
    });

    // Calculate Task stats per user
    const taskStats = new Map();
    for (const t of tasks) {
      if (!taskStats.has(t.assignedToId)) {
        taskStats.set(t.assignedToId, { total: 0, completed: 0 });
      }
      const stats = taskStats.get(t.assignedToId);
      stats.total += 1;
      if (t.status === 'Completed') {
        stats.completed += 1;
      }
    }

    // Fetch Checklist Templates
    const templates = await prisma.checklistTemplate.findMany({
      where: {
        userId: { in: userIds },
        status: 'Active'
      }
    });

    // Helper to calculate how many times a template is due between start and end
    const getOccurrences = (frequency: string, freqValue: number | null, s: Date, e: Date) => {
      let count = 0;
      let curr = new Date(s);
      curr.setUTCHours(0, 0, 0, 0);
      const endLimit = new Date(e);
      endLimit.setUTCHours(23, 59, 59, 999);

      while (curr <= endLimit) {
        if (frequency === 'Daily') {
          count++;
        } else if (frequency === 'Weekly') {
          const jsDay = curr.getUTCDay();
          const expectedDay = jsDay === 0 ? 7 : jsDay;
          if (freqValue === expectedDay) count++;
        } else if (frequency === 'Monthly') {
          if (freqValue === curr.getUTCDate()) count++;
        }
        curr.setUTCDate(curr.getUTCDate() + 1);
      }
      return count;
    };

    const checklistDueStats = new Map();
    for (const t of templates) {
      const dueCount = getOccurrences(t.frequency, t.frequencyValue, start, end);
      if (!checklistDueStats.has(t.userId)) {
        checklistDueStats.set(t.userId, 0);
      }
      checklistDueStats.set(t.userId, checklistDueStats.get(t.userId) + dueCount);
    }

    // Fetch Completed Checklist Logs
    const checklistLogs = await prisma.checklistLog.findMany({
      where: {
        userId: { in: userIds },
        status: 'Completed',
        date: {
          gte: start,
          lte: end
        }
      },
      select: {
        userId: true
      }
    });

    const checklistCompletedStats = new Map();
    for (const log of checklistLogs) {
      if (!checklistCompletedStats.has(log.userId)) {
        checklistCompletedStats.set(log.userId, 0);
      }
      checklistCompletedStats.set(log.userId, checklistCompletedStats.get(log.userId) + 1);
    }

    // Fetch Daily Work Logs for Time and Quantity
    const dailyLogs = await prisma.dailyWorkLog.findMany({
      where: {
        userId: { in: userIds },
        date: { gte: start, lte: end }
      },
      include: { entries: true }
    });

    const timeStats = new Map();
    const quantityStats = new Map();
    
    for (const log of dailyLogs) {
      if (!timeStats.has(log.userId)) timeStats.set(log.userId, 0);
      timeStats.set(log.userId, timeStats.get(log.userId) + (log.totalHours || 0));

      let totalQty = 0;
      for (const entry of log.entries) {
        if (entry.quantity) {
          // Attempt to parse number from string like "10 pairs"
          const parsed = parseFloat(entry.quantity.replace(/[^0-9.]/g, ''));
          if (!isNaN(parsed)) {
            totalQty += parsed;
          }
        }
      }
      if (!quantityStats.has(log.userId)) quantityStats.set(log.userId, 0);
      quantityStats.set(log.userId, quantityStats.get(log.userId) + totalQty);
    }

    // Fetch QC Logs for Quality
    const qcLogs = await prisma.qCDailyLog.findMany({
      where: {
        userId: { in: userIds },
        date: { gte: start, lte: end }
      },
      include: { entries: true }
    });

    const qualityStats = new Map();
    for (const log of qcLogs) {
      let totalQc = 0;
      for (const entry of log.entries) {
        totalQc += (entry.quantity || 0);
      }
      if (!qualityStats.has(log.userId)) qualityStats.set(log.userId, 0);
      qualityStats.set(log.userId, qualityStats.get(log.userId) + totalQc);
    }

    // Combine Data
    const reportData = users.map(u => {
      const tStats = taskStats.get(u.id) || { total: 0, completed: 0 };
      const pendingTasks = tStats.total - tStats.completed;
      const taskScore = (tStats.completed - tStats.total) * 10;

      const cTotal = checklistDueStats.get(u.id) || 0;
      const cCompleted = checklistCompletedStats.get(u.id) || 0;
      const pendingChecklists = cTotal - cCompleted;
      const cPending = pendingChecklists > 0 ? pendingChecklists : 0; 
      const checklistScore = (cCompleted - cTotal) * 10;

      const timeLogged = timeStats.get(u.id) || 0;
      const quantityLogged = quantityStats.get(u.id) || 0;
      const qualityLogged = qualityStats.get(u.id) || 0;
      const costLogged = timeLogged * 100; // Using dummy rate of 100/hr

      return {
        userId: u.id,
        employeeId: u.employeeId,
        name: u.name,
        department: u.department?.name || 'N/A',
        role: u.role?.name || 'N/A',
        tasks: {
          total: tStats.total,
          completed: tStats.completed,
          pending: pendingTasks > 0 ? pendingTasks : 0,
          score: tStats.total === 0 ? 0 : (taskScore > 0 ? 0 : taskScore),
        },
        checklists: {
          total: cTotal,
          completed: cCompleted,
          pending: cPending,
          score: cTotal === 0 ? 0 : (checklistScore > 0 ? 0 : checklistScore),
        },
        metrics: {
          time: timeLogged,
          quantity: quantityLogged,
          quality: qualityLogged,
          cost: costLogged,
        }
      };
    });

    res.json(reportData);

  } catch (error) {
    console.error('Error fetching MIS reports:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
