import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const monthsOrder = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

// Helper to get 'Apr-26' from Date
function getMonthStr(d: Date): string {
    const m = monthNames[d.getUTCMonth()];
    const y = d.getUTCFullYear().toString().slice(2);
    return `${m}-${y}`;
}

export const getAopSummary = async (req: Request, res: Response) => {
    try {
        const fy = req.query.fy as string || '2026-27';
        // In reality, fy could filter target by FY if added to schema, but currently targets are across months.
        const targets = await prisma.aopTarget.findMany();
        const achieved = await prisma.aopAchieved.findMany();

        const categoriesSet = new Set<string>();
        targets.forEach(t => categoriesSet.add(t.category));
        
        const achievedMap: Record<string, Record<string, number>> = {};
        for (const item of achieved) {
            const ms = getMonthStr(new Date(item.date));
            if (!achievedMap[item.category]) achievedMap[item.category] = {};
            achievedMap[item.category][ms] = (achievedMap[item.category][ms] || 0) + item.quantity;
        }

        const activeMonths = ['Apr-26', 'May-26', 'Jun-26']; // Mocking current YTD
        const isMTD = [false, false, true]; // Jun is MTD

        const targetsResponse: Record<string, number[]> = {};
        const actualsResponse: Record<string, number[]> = {};

        Array.from(categoriesSet).forEach(cat => {
            targetsResponse[cat] = [];
            actualsResponse[cat] = [];
            
            const catTargets = targets.filter(t => t.category === cat);
            const targetDict: Record<string, number> = {};
            catTargets.forEach(t => targetDict[t.month] = t.target);

            for (const m of activeMonths) {
                targetsResponse[cat].push(targetDict[m] || 0);
                actualsResponse[cat].push(achievedMap[cat]?.[m] || 0);
            }
        });

        res.json({
            categories: Array.from(categoriesSet),
            months: activeMonths,
            targets: targetsResponse,
            actuals: actualsResponse,
            isMTD
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
};

export const getAopMonthly = async (req: Request, res: Response) => {
    try {
        const monthIndex = parseInt(req.query.month as string || '2'); // default to Jun
        const activeMonths = ['Apr-26', 'May-26', 'Jun-26'];
        if (monthIndex < 0 || monthIndex >= activeMonths.length) {
            return res.status(400).json({ message: 'Invalid month index' });
        }
        const m = activeMonths[monthIndex];
        const isMTD = monthIndex === 2;

        const targets = await prisma.aopTarget.findMany({ where: { month: m } });
        const achieved = await prisma.aopAchieved.findMany();

        const achievedMap: Record<string, number> = {};
        for (const item of achieved) {
            if (getMonthStr(new Date(item.date)) === m) {
                achievedMap[item.category] = (achievedMap[item.category] || 0) + item.quantity;
            }
        }

        const rows = targets.map(t => {
            const actual = achievedMap[t.category] || 0;
            const shortfall = Math.max(0, t.target - actual);
            const pct = t.target > 0 ? Math.round((actual / t.target) * 100) : 0;
            let status = 'na';
            if (t.target > 0) {
                if (pct >= 90) status = 'achieved';
                else if (pct >= 50) status = 'atRisk';
                else status = 'critical';
            }
            return {
                category: t.category,
                target: t.target,
                actual,
                shortfall,
                achievementPct: pct,
                status
            };
        });

        const totals = rows.reduce((acc, r) => {
            acc.target += r.target;
            acc.actual += r.actual;
            acc.shortfall += r.shortfall;
            return acc;
        }, { category: 'TOTAL', target: 0, actual: 0, shortfall: 0, achievementPct: 0, status: 'na' });
        
        totals.achievementPct = totals.target > 0 ? Math.round((totals.actual / totals.target) * 100) : 0;

        res.json({
            month: m,
            monthIndex,
            isMTD,
            rows,
            totals
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
};

export const getAopDrilldown = async (req: Request, res: Response) => {
    try {
        const { category, month } = req.query;
        if (!category || !month) return res.status(400).json({ message: 'Missing params' });

        const activeMonths = ['Apr-26', 'May-26', 'Jun-26'];
        const m = activeMonths[parseInt(month as string)];

        const targetRow = await prisma.aopTarget.findFirst({ where: { category: category as string, month: m } });
        const target = targetRow?.target || 0;

        const achieved = await prisma.aopAchieved.findMany({ where: { category: category as string } });
        
        const monthAchieved = achieved.filter(a => getMonthStr(new Date(a.date)) === m);
        const actual = monthAchieved.reduce((sum, a) => sum + a.quantity, 0);

        const specsMap: Record<string, { qty: number, first: Date, last: Date, count: number }> = {};
        for (const a of monthAchieved) {
            const s = a.spec || '';
            if (!specsMap[s]) specsMap[s] = { qty: 0, first: new Date(a.date), last: new Date(a.date), count: 0 };
            specsMap[s].qty += a.quantity;
            specsMap[s].count += 1;
            const d = new Date(a.date);
            if (d < specsMap[s].first) specsMap[s].first = d;
            if (d > specsMap[s].last) specsMap[s].last = d;
        }

        const specs = Object.keys(specsMap).map(s => {
            const data = specsMap[s];
            return {
                specCode: s.split(' - ')[0],
                specFull: s,
                totalQty: data.qty,
                sharePct: actual > 0 ? Math.round((data.qty / actual) * 100) : 0,
                firstDate: data.first.toISOString(),
                lastDate: data.last.toISOString(),
                dispatchCount: data.count
            };
        });

        res.json({ category, month: m, target, actual, specs });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
};

export const getAopTransactions = async (req: Request, res: Response) => {
    try {
        const { category, month, search, page = '1' } = req.query;
        const pageNum = parseInt(page as string);
        const take = 20;
        const skip = (pageNum - 1) * take;

        const activeMonths = ['Apr-26', 'May-26', 'Jun-26'];
        
        const all = await prisma.aopAchieved.findMany();
        
        let filtered = all;
        if (category) filtered = filtered.filter(a => a.category === category);
        if (month) {
            const mStr = activeMonths[parseInt(month as string)];
            filtered = filtered.filter(a => getMonthStr(new Date(a.date)) === mStr);
        }
        if (search) {
            const s = (search as string).toLowerCase();
            filtered = filtered.filter(a => (a.spec || '').toLowerCase().includes(s));
        }

        // Pagination
        const total = filtered.length;
        const data = filtered.slice(skip, skip + take).map(a => ({
            id: a.id,
            dispatchDate: a.date.toISOString(),
            category: a.category,
            specification: a.spec || '',
            quantity: a.quantity,
            uom: 'NOs'
        }));

        res.json({
            data,
            total,
            page: pageNum,
            totalPages: Math.ceil(total / take)
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
};

export const getAopTable = async (req: Request, res: Response) => {
    try {
        const targets = await prisma.aopTarget.findMany();
        const achieved = await prisma.aopAchieved.findMany();

        const achievedMap: Record<string, Record<string, number>> = {};
        for (const item of achieved) {
            const ms = getMonthStr(new Date(item.date));
            if (!achievedMap[item.category]) achievedMap[item.category] = {};
            achievedMap[item.category][ms] = (achievedMap[item.category][ms] || 0) + item.quantity;
        }

        const categoriesSet = new Set<string>();
        targets.forEach(t => categoriesSet.add(t.category));

        const analysis = Array.from(categoriesSet).map(category => {
            const catTargets = targets.filter(t => t.category === category);
            const targetObj: Record<string, number> = {};
            catTargets.forEach(t => targetObj[t.month] = t.target);

            const achievedObj = achievedMap[category] || {};
            const shortfallObj: Record<string, number> = {};
            
            const allMonths = new Set([...Object.keys(targetObj), ...Object.keys(achievedObj)]);
            for (const m of Array.from(allMonths)) {
                shortfallObj[m] = (targetObj[m] || 0) - (achievedObj[m] || 0);
            }

            return {
                category,
                targets: targetObj,
                achieved: achievedObj,
                shortfall: shortfallObj
            };
        });

        res.json(analysis);
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
};
