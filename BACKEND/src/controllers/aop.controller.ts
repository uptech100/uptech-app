import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getAopAnalysis = async (req: Request, res: Response) => {
  try {
    const targets = await prisma.aopTarget.findMany();
    const achieved = await prisma.aopAchieved.findMany();

    // Group achieved by category and month (e.g. 'Apr-26')
    // We'll format the achieved date to match the target month string ('MMM-YY')
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    const achievedMap: Record<string, Record<string, number>> = {};
    
    for (const item of achieved) {
      const d = new Date(item.date);
      const m = monthNames[d.getUTCMonth()];
      const y = d.getUTCFullYear().toString().slice(2);
      const monthStr = `${m}-${y}`; // e.g., 'Apr-26'
      
      const cat = item.category;
      if (!achievedMap[cat]) achievedMap[cat] = {};
      if (!achievedMap[cat][monthStr]) achievedMap[cat][monthStr] = 0;
      
      achievedMap[cat][monthStr] += item.quantity;
    }

    // Now format the response grouped by category
    const categoriesSet = new Set<string>();
    targets.forEach(t => categoriesSet.add(t.category));
    achieved.forEach(a => categoriesSet.add(a.category));

    const analysis = Array.from(categoriesSet).map(category => {
      const catTargets = targets.filter(t => t.category === category);
      
      const targetObj: Record<string, number> = {};
      catTargets.forEach(t => targetObj[t.month] = t.target);

      const achievedObj = achievedMap[category] || {};

      // Calculate shortfall
      const shortfallObj: Record<string, number> = {};
      // For all months that exist in targets or achieved
      const allMonths = new Set([...Object.keys(targetObj), ...Object.keys(achievedObj)]);
      
      // Sort months generally (we can just rely on the frontend to sort or render)
      for (const month of Array.from(allMonths)) {
        const t = targetObj[month] || 0;
        const a = achievedObj[month] || 0;
        shortfallObj[month] = t - a;
      }

      return {
        category,
        targets: targetObj,
        achieved: achievedObj,
        shortfall: shortfallObj
      };
    });

    res.json(analysis);

  } catch (error) {
    console.error('Error fetching AOP analysis:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
