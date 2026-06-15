import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getDashboardData = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;
    const role = (req as any).user?.role;
    
    // Base data for all users
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { department: true }
    });

    const unreadNotifications = await prisma.notification.count({
      where: { userId, isRead: false }
    });

    let dashboardData: any = {
      profile: user,
      unreadNotifications,
    };

    // Role-specific analytics
    if (role === 'Worker') {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const todaysTasks = await prisma.task.count({
        where: {
          assignedToId: userId,
          createdAt: { gte: today }
        }
      });

      const pendingTasks = await prisma.task.count({
        where: {
          assignedToId: userId,
          status: 'Pending'
        }
      });

      const completedTasks = await prisma.task.count({
        where: {
          assignedToId: userId,
          status: 'Completed'
        }
      });

      dashboardData.analytics = {
        todaysTasks,
        pendingTasks,
        completedTasks
      };
    } else if (role === 'MD' || role === 'Admin') {
      dashboardData.analytics = {
        totalEmployees: await prisma.user.count(),
        totalDepartments: await prisma.department.count(),
        pendingTasks: await prisma.task.count({ where: { status: 'Pending' } }),
      };
    }

    res.json(dashboardData);

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ message: 'Failed to fetch dashboard data' });
  }
};
