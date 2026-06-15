import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getTodayLog = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const dateQuery = req.query.date as string;
    
    let targetDate = new Date();
    if (dateQuery) {
      targetDate = new Date(`${dateQuery}T00:00:00.000Z`);
    } else {
      // Local server midnight shifted to UTC for storage
      targetDate.setHours(0, 0, 0, 0);
      targetDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()));
    }

    let log = await prisma.dailyWorkLog.findUnique({
      where: {
        userId_date: {
          userId,
          date: targetDate,
        },
      },
      include: {
        entries: {
          include: {
            process: true,
            product: true,
          },
          orderBy: { startTime: 'asc' },
        },
      },
    });

    if (!log) {
      log = await prisma.dailyWorkLog.create({
        data: {
          userId,
          date: targetDate,
          totalHours: 0,
          isLocked: false,
        },
        include: {
          entries: {
            include: { process: true, product: true },
          },
        },
      });
    }

    res.json(log);
  } catch (error) {
    console.error('Error fetching today log:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const addWorkEntry = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { logId, startTime, endTime, processId, productId, size, sjoNumber, quantity, uom, remarks } = req.body;

    const log = await prisma.dailyWorkLog.findUnique({ where: { id: Number(logId) } });
    if (!log || log.userId !== userId) {
      return res.status(404).json({ message: 'Log not found' });
    }
    if (log.isLocked) {
      return res.status(403).json({ message: 'Log is locked. You cannot add more entries.' });
    }

    const start = new Date(startTime);
    const end = new Date(endTime);
    const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);

    if (hours <= 0) {
      return res.status(400).json({ message: 'End time must be after start time' });
    }

    const entry = await prisma.workEntry.create({
      data: {
        dailyLogId: log.id,
        startTime: start,
        endTime: end,
        processId: Number(processId),
        productId: Number(productId),
        size,
        sjoNumber,
        quantity,
        uom,
        remarks,
      },
      include: {
        process: true,
        product: true,
      },
    });

    // Update total hours
    const updatedLog = await prisma.dailyWorkLog.update({
      where: { id: log.id },
      data: { totalHours: log.totalHours + hours },
      include: {
        entries: {
          include: { process: true, product: true },
          orderBy: { startTime: 'asc' },
        },
      },
    });

    res.status(201).json(updatedLog);
  } catch (error) {
    console.error('Error adding work entry:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateWorkEntry = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const entryId = Number(req.params.id);
    const { quantity, uom, remarks, size } = req.body;

    const entry = await prisma.workEntry.findUnique({
      where: { id: entryId },
      include: { dailyLog: true }
    });

    if (!entry || entry.dailyLog.userId !== userId) {
      return res.status(404).json({ message: 'Entry not found or unauthorized' });
    }

    const updatedEntry = await prisma.workEntry.update({
      where: { id: entryId },
      data: {
        quantity,
        uom,
        remarks,
        size
      },
      include: {
        process: true,
        product: true,
      }
    });

    res.json(updatedEntry);
  } catch (error) {
    console.error('Error updating work entry:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const finalizeLog = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { logId } = req.body;

    const log = await prisma.dailyWorkLog.findUnique({ where: { id: Number(logId) } });
    if (!log || log.userId !== userId) {
      return res.status(404).json({ message: 'Log not found' });
    }

    // Only allow finalizing if they have at least 10 hours, but wait! The user approved my plan where it's a warning.
    // So the UI warns them, and if they click "Submit Anyway", it finalizes. So backend allows it.
    
    const updatedLog = await prisma.dailyWorkLog.update({
      where: { id: log.id },
      data: { isLocked: true },
      include: {
        entries: {
          include: { process: true, product: true },
          orderBy: { startTime: 'asc' },
        },
      },
    });

    res.json(updatedLog);
  } catch (error) {
    console.error('Error finalizing log:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getWorkHistory = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const logs = await prisma.dailyWorkLog.findMany({
      where: { userId },
      include: {
        entries: {
          include: { process: true, product: true },
          orderBy: { startTime: 'asc' },
        },
      },
      orderBy: { date: 'desc' },
    });

    res.json(logs);
  } catch (error) {
    console.error('Error fetching work history:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getWorkerOptions = async (req: Request, res: Response) => {
  try {
    const [processes, products] = await Promise.all([
      prisma.workProcess.findMany({ where: { status: 'Active' }, orderBy: { name: 'asc' } }),
      prisma.workProduct.findMany({ where: { status: 'Active' }, orderBy: { name: 'asc' } }),
    ]);

    res.json({ processes, products });
  } catch (error) {
    console.error('Error fetching worker options:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
