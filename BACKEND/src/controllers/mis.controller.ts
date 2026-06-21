import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getWorkerMis = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({ message: 'startDate and endDate are required' });
    }

    const start = new Date(startDate as string);
    const end = new Date(endDate as string);
    end.setUTCHours(23, 59, 59, 999);

    // Calculate Expected Hours (8 hours per day, excluding Sundays usually, but let's just do 8 * days)
    const getDaysBetween = (d1: Date, d2: Date) => {
      let count = 0;
      let curr = new Date(d1);
      curr.setUTCHours(0, 0, 0, 0);
      const e = new Date(d2);
      e.setUTCHours(23, 59, 59, 999);
      while (curr <= e) {
        // Exclude Sundays (0) if needed, but for simplicity we count all days, or just weekdays
        // Let's exclude Sundays
        if (curr.getUTCDay() !== 0) {
          count++;
        }
        curr.setUTCDate(curr.getUTCDate() + 1);
      }
      return count;
    };
    const days = getDaysBetween(start, end);
    const expectedHours = days * 8;

    // 1. Task Score
    const tasks = await prisma.task.findMany({
      where: {
        assignedToId: userId,
        createdAt: { gte: start, lte: end }
      }
    });
    let totalTasks = tasks.length;
    let completedTasks = tasks.filter(t => t.status === 'Completed').length;
    let taskScore = totalTasks === 0 ? 0 : (completedTasks - totalTasks) * 10;
    if (taskScore > 0) taskScore = 0;

    // 2. Work Logs (Time & Quantity & Process Breakdown)
    const logs = await prisma.dailyWorkLog.findMany({
      where: {
        userId: userId,
        date: { gte: start, lte: end }
      },
      include: {
        entries: {
          include: { process: true }
        }
      }
    });

    let totalWorkHours = 0;
    let totalQuantity = 0;
    const processBreakdown: Record<string, number> = {};

    for (const log of logs) {
      totalWorkHours += log.totalHours || 0;
      for (const entry of log.entries) {
        // Time per process
        const processName = entry.process?.name || 'Unknown';
        const startT = new Date(entry.startTime).getTime();
        const endT = new Date(entry.endTime).getTime();
        const durationHours = (endT - startT) / (1000 * 60 * 60);

        if (!processBreakdown[processName]) {
          processBreakdown[processName] = 0;
        }
        processBreakdown[processName] += durationHours;

        // Quantity
        if (entry.quantity) {
          const parsed = parseFloat(entry.quantity.replace(/[^0-9.]/g, ''));
          if (!isNaN(parsed)) {
            totalQuantity += parsed;
          }
        }
      }
    }

    // 3. Worker Score based on Hours
    // e.g. Score = (totalWorkHours - expectedHours) * 5
    // If they worked more than expected, score is positive. If less, negative.
    const workerScore = (totalWorkHours - expectedHours) * 5;

    res.json({
      taskScore,
      totalTasks,
      completedTasks,
      totalWorkHours,
      expectedHours,
      totalQuantity,
      workerScore,
      processBreakdown: Object.keys(processBreakdown).map(k => ({
        process: k,
        hours: processBreakdown[k]
      }))
    });

  } catch (error) {
    console.error('Error fetching worker MIS:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
