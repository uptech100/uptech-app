import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      where: { status: 'Active' },
      select: { id: true, name: true, employeeId: true },
      orderBy: { name: 'asc' },
    });
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Failed to fetch users' });
  }
};

export const getTodaysTasks = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tasks = await prisma.task.findMany({
      where: {
        assignedToId: userId,
      },
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(tasks);
  } catch (error) {
    console.error('Error fetching today\'s tasks:', error);
    res.status(500).json({ message: 'Failed to fetch tasks' });
  }
};

export const getTasksAssignedByMe = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;

    const tasks = await prisma.task.findMany({
      where: {
        createdById: userId,
      },
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(tasks);
  } catch (error) {
    console.error('Error fetching assigned tasks:', error);
    res.status(500).json({ message: 'Failed to fetch assigned tasks' });
  }
};

export const getAllTasks = async (req: Request, res: Response) => {
  try {
    const tasks = await prisma.task.findMany({
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(tasks);
  } catch (error) {
    console.error('Error fetching all tasks:', error);
    res.status(500).json({ message: 'Failed to fetch tasks' });
  }
};

export const createTask = async (req: Request, res: Response) => {
  try {
    const createdById = (req as any).user?.userId;
    const { title, description, assignedToId, dueDate, priority } = req.body;

    if (!title || !assignedToId) {
      return res.status(400).json({ message: 'Title and assignedToId are required' });
    }

    const task = await prisma.task.create({
      data: {
        title: title.trim(),
        description: description?.trim() || null,
        assignedToId: Number(assignedToId),
        createdById,
        dueDate: dueDate ? new Date(dueDate) : null,
        priority: priority || 'Normal',
        status: 'Pending',
        startTime: new Date(),
      },
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
    });

    res.status(201).json(task);
  } catch (error) {
    console.error('Error creating task:', error);
    res.status(500).json({ message: 'Failed to create task' });
  }
};

export const markTaskComplete = async (req: Request, res: Response) => {
  try {
    const { taskId } = req.params;
    const { timeTaken } = req.body;
    const userId = (req as any).user?.userId;

    const task = await prisma.task.update({
      where: { id: Number(taskId) },
      data: {
        status: 'Completed',
        endTime: new Date(),
        timeTaken: timeTaken ? Number(timeTaken) : null,
      },
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
    });

    res.json({ message: 'Task marked as complete', task });
  } catch (error) {
    console.error('Error completing task:', error);
    res.status(500).json({ message: 'Failed to complete task' });
  }
};

export const reopenTask = async (req: Request, res: Response) => {
  try {
    const { taskId } = req.params;
    const userId = (req as any).user?.userId;

    // Verify the user owns this task (they created it)
    const existingTask = await prisma.task.findUnique({
      where: { id: Number(taskId) }
    });

    if (!existingTask) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (existingTask.createdById !== userId) {
      return res.status(403).json({ message: 'You are not authorized to reopen this task' });
    }

    const task = await prisma.task.update({
      where: { id: Number(taskId) },
      data: {
        status: 'Reopened',
        endTime: null,
        timeTaken: null,
        reopenCount: { increment: 1 }
      },
      include: {
        createdBy: { select: { name: true } },
        assignedTo: { select: { name: true } },
      },
    });

    res.json({ message: 'Task reopened successfully', task });
  } catch (error) {
    console.error('Error reopening task:', error);
    res.status(500).json({ message: 'Failed to reopen task' });
  }
};
