import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const createChecklistTemplate = async (req: Request, res: Response) => {
  try {
    const { taskName, departmentId, userId, frequency, frequencyValue } = req.body;

    if (!taskName || !departmentId || !userId || !frequency) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const template = await prisma.checklistTemplate.create({
      data: {
        taskName,
        departmentId: Number(departmentId),
        userId: Number(userId),
        frequency,
        frequencyValue: frequencyValue ? Number(frequencyValue) : null,
      },
      include: {
        department: true,
        user: { select: { id: true, name: true, employeeId: true } },
      },
    });

    res.status(201).json(template);
  } catch (error) {
    console.error('Error creating checklist template:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getAdminChecklists = async (req: Request, res: Response) => {
  try {
    const templates = await prisma.checklistTemplate.findMany({
      include: {
        department: true,
        user: { select: { id: true, name: true, employeeId: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(templates);
  } catch (error) {
    console.error('Error fetching admin checklists:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getMyChecklists = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const dateQuery = req.query.date as string;

    if (!dateQuery) {
      return res.status(400).json({ message: 'Date is required (YYYY-MM-DD)' });
    }

    const targetDate = new Date(`${dateQuery}T00:00:00.000Z`);

    // Fetch all active templates for this user
    const templates = await prisma.checklistTemplate.findMany({
      where: {
        userId: userId,
        status: 'Active',
      },
    });

    // We filter templates that are "due" on this date
    // Daily -> always due
    // Weekly -> due if day of week matches (0 = Sunday, 1 = Monday)
    // Monthly -> due if day of month matches
    const dueTemplates = templates.filter(t => {
      if (t.frequency === 'Daily') return true;
      if (t.frequency === 'Weekly') {
        // frequencyValue: 1-7 (1=Mon, 7=Sun) based on ISO, but let's assume UI maps them.
        // Javascript getUTCDay() is 0-6 (0=Sun, 1=Mon)
        const jsDay = targetDate.getUTCDay(); // 0 is Sunday
        const expectedDay = jsDay === 0 ? 7 : jsDay; // Convert to 1-7 (1=Mon, 7=Sun)
        return t.frequencyValue === expectedDay;
      }
      if (t.frequency === 'Monthly') {
        return t.frequencyValue === targetDate.getUTCDate();
      }
      return false;
    });

    // For all due templates, check if a ChecklistLog exists for targetDate
    const templateIds = dueTemplates.map(t => t.id);
    const logs = await prisma.checklistLog.findMany({
      where: {
        userId: userId,
        date: targetDate,
        templateId: { in: templateIds },
      },
    });

    const logsMap = new Map();
    for (const log of logs) {
      logsMap.set(log.templateId, log);
    }

    // Map into view models
    const result = dueTemplates.map(template => {
      const log = logsMap.get(template.id);
      return {
        id: template.id,
        taskName: template.taskName,
        frequency: template.frequency,
        status: log ? log.status : 'Pending', // Pending if no log exists
        logId: log ? log.id : null,
      };
    });

    res.json(result);
  } catch (error) {
    console.error('Error fetching my checklists:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const markChecklistComplete = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { templateId, date, remarks } = req.body;

    if (!templateId || !date) {
      return res.status(400).json({ message: 'Template ID and Date are required' });
    }

    const targetDate = new Date(`${date}T00:00:00.000Z`);

    const log = await prisma.checklistLog.upsert({
      where: {
        templateId_date: {
          templateId: Number(templateId),
          date: targetDate,
        },
      },
      update: {
        status: 'Completed',
        completedAt: new Date(),
        remarks,
      },
      create: {
        templateId: Number(templateId),
        userId: userId,
        date: targetDate,
        status: 'Completed',
        completedAt: new Date(),
        remarks,
      },
    });

    res.json(log);
  } catch (error) {
    console.error('Error completing checklist:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getChecklistHistory = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const logs = await prisma.checklistLog.findMany({
      where: {
        userId: userId,
        status: 'Completed',
      },
      include: {
        template: true,
      },
      orderBy: {
        date: 'desc',
      },
      take: 50, // Get last 50 completed checklists
    });

    res.json(logs);
  } catch (error) {
    console.error('Error fetching checklist history:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
