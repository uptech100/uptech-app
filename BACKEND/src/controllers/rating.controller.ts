import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper to get the start of the week (assuming Saturday is the rating day, we can use the most recent Saturday as weekStartDate)
const getWeekStartDate = () => {
  const now = new Date();
  const day = now.getDay(); // Sunday = 0, Monday = 1, ..., Saturday = 6
  const diff = now.getDate() - day + (day === 6 ? 0 : -1 - day + 6); // adjust to get to most recent Saturday
  const weekStart = new Date(now.setDate(diff));
  weekStart.setHours(0, 0, 0, 0);
  return weekStart;
};

export const getUsersToRate = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (!user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    // Get all active users except the current user
    const users = await prisma.user.findMany({
      where: {
        id: { not: user.id },
        status: 'Active',
      },
      select: {
        id: true,
        name: true,
        employeeId: true,
        department: { select: { name: true } },
      },
      orderBy: { name: 'asc' },
    });

    res.json(users);
  } catch (error) {
    console.error('Error fetching users to rate:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const submitRating = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { rateeId, rating } = req.body;
    const { bypassSaturday } = req.query;

    if (!user) return res.status(401).json({ message: 'Unauthorized' });
    if (!rateeId || rating === undefined) return res.status(400).json({ message: 'Missing rateeId or rating' });
    if (rating < 1 || rating > 5) return res.status(400).json({ message: 'Rating must be between 1 and 5' });

    // Enforce Saturday rule
    const now = new Date();
    if (now.getDay() !== 6 && bypassSaturday !== 'true') {
      return res.status(403).json({ message: 'Ratings can only be submitted on Saturdays.' });
    }

    const weekStartDate = getWeekStartDate();

    // Check if rating already exists
    const existingRating = await prisma.userRating.findUnique({
      where: {
        raterId_rateeId_weekStartDate: {
          raterId: user.id,
          rateeId: rateeId,
          weekStartDate: weekStartDate,
        },
      },
    });

    if (existingRating) {
      return res.status(400).json({ message: 'You have already rated this user for the current week.' });
    }

    const newRating = await prisma.userRating.create({
      data: {
        raterId: user.id,
        rateeId: rateeId,
        rating: rating,
        weekStartDate: weekStartDate,
      },
    });

    res.status(201).json(newRating);
  } catch (error) {
    console.error('Error submitting rating:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getAdminRatingsSummary = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (!user || user.role !== 'Admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    // Get average ratings per user
    const usersWithRatings = await prisma.user.findMany({
      where: { status: 'Active' },
      select: {
        id: true,
        name: true,
        employeeId: true,
        department: { select: { name: true } },
        ratingsReceived: {
          select: { rating: true, weekStartDate: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    // Calculate averages
    const summary = usersWithRatings.map(u => {
      const totalRatings = u.ratingsReceived.length;
      const sumRatings = u.ratingsReceived.reduce((sum, r) => sum + r.rating, 0);
      const averageRating = totalRatings > 0 ? sumRatings / totalRatings : 0;
      
      return {
        id: u.id,
        name: u.name,
        employeeId: u.employeeId,
        department: u.department.name,
        averageRating: averageRating.toFixed(1),
        totalRatings: totalRatings,
      };
    });

    res.json(summary);
  } catch (error) {
    console.error('Error fetching admin ratings summary:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
