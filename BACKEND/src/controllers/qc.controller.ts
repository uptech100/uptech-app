import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

function inferCategory(description: string): string {
  const desc = description.toUpperCase();
  if (desc.includes('SHEET METAL LIFTER')) return 'SHEET METAL LIFTER';
  if (desc.includes('LIFTER')) return 'Magnetic Lifters';
  if (desc.includes('NON MAG') && desc.includes('V BLOCK')) return 'NON MAGNETIC V BLOCK';
  if (desc.includes('ROLLER BEARING V BLOCK')) return 'Roller Bearing V Block';
  if (desc.includes('V BLOCK')) return 'MAGNETIC V BLOCK'; // Fallback for other V blocks
  if (desc.includes('CHUCK')) return 'Chucks';
  if (desc.includes('PARALLEL BLOCK')) return 'Parallel Blocks';
  if (desc.includes('SINE TABLE')) return 'SINE TABLE';
  if (desc.includes('RECTANGULAR BLOCK')) return 'MAGNETIC RECTANGULAR BLOCKS';
  if (desc.includes('VICE')) return 'GRINDING VICE';
  if (desc.includes('MAGNETIC BASE') || desc.includes('HOLDING MAGNET')) return 'MAGNETIC HOLDER';
  return 'OTHERS';
}

export const importQCItems = async (req: Request, res: Response) => {
  try {
    const tsvPath = path.join(__dirname, '../../raw_qc_items.tsv');
    const fileContent = fs.readFileSync(tsvPath, 'utf-8');
    
    const lines = fileContent.split('\n').filter(line => line.trim() !== '');
    
    // Skip header line
    const dataLines = lines.slice(1);
    
    let importedCount = 0;
    
    for (const line of dataLines) {
      const parts = line.split('\t');
      if (parts.length < 5) continue; // Basic validation
      
      const itemCode = parts[0].trim();
      const itemName = parts[1].trim();
      const uom = parts[2].trim();
      const hsnCode = parts[3].trim() || null;
      const description = parts[4].trim();
      
      if (!itemCode || !description) continue;
      
      const category = inferCategory(description);
      
      await prisma.qCItem.upsert({
        where: { itemCode },
        update: {
          description,
          uom,
          category,
          hsnCode
        },
        create: {
          itemCode,
          description,
          uom,
          category,
          hsnCode
        }
      });
      importedCount++;
    }
    
    res.status(200).json({ message: `Successfully imported ${importedCount} QC Items.` });
  } catch (error: any) {
    console.error('Error importing QC items:', error);
    res.status(500).json({ error: error.message });
  }
};

export const getQCItems = async (req: Request, res: Response) => {
  try {
    const items = await prisma.qCItem.findMany({
      orderBy: { itemCode: 'asc' }
    });
    
    // Also return distinct categories for convenience
    const categories = Array.from(new Set(items.map(i => i.category)));
    
    res.status(200).json({ categories, items });
  } catch (error: any) {
    console.error('Error fetching QC items:', error);
    res.status(500).json({ error: error.message });
  }
};

export const addQCItem = async (req: Request, res: Response) => {
  try {
    const { itemCode, description, uom, category, hsnCode } = req.body;
    
    if (!itemCode || !description || !category) {
      return res.status(400).json({ error: 'Item Code, Description, and Category are required.' });
    }

    // Check if itemCode already exists
    const existing = await prisma.qCItem.findUnique({ where: { itemCode } });
    if (existing) {
      return res.status(400).json({ error: 'Item Code already exists.' });
    }

    const newItem = await prisma.qCItem.create({
      data: {
        itemCode,
        description,
        uom: uom || null,
        category,
        hsnCode: hsnCode || null,
      }
    });

    res.status(201).json(newItem);
  } catch (error: any) {
    console.error('Error adding QC item:', error);
    res.status(500).json({ error: error.message });
  }
};

export const submitQCReport = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user!.userId;
    const { date, entries } = req.body;
    
    if (!date || !entries || !Array.isArray(entries)) {
      return res.status(400).json({ error: 'Missing date or entries array.' });
    }
    
    let targetDate = new Date(date);
    targetDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()));
    
    // Use transaction to ensure data integrity
    const qcLog = await prisma.$transaction(async (tx) => {
      // Upsert log for the date and user
      const log = await tx.qCDailyLog.upsert({
        where: {
          userId_date: {
            userId,
            date: targetDate,
          }
        },
        update: {},
        create: {
          userId,
          date: targetDate,
        }
      });
      
      // Delete old entries if any (so we can just replace them, or maybe we append? Usually daily log is final submit)
      // Let's assume we append entries. So we just create new entries.
      
      for (const entry of entries) {
        if (!entry.itemCode || typeof entry.quantity !== 'number') continue;
        
        let item = await tx.qCItem.findUnique({ where: { itemCode: entry.itemCode } });
        if (!item) {
          // Auto create QC Item if it doesn't exist
          item = await tx.qCItem.create({
            data: {
              itemCode: entry.itemCode,
              category: entry.category || 'General',
              description: entry.description || '',
              uom: entry.uom || 'NOS',
            }
          });
        }
        
        await tx.qCReportEntry.create({
          data: {
            qcLogId: log.id,
            qcItemId: item.id,
            process: entry.process || 'Finish Checking',
            quantity: entry.quantity,
            size: entry.size || null,
            uom: entry.uom || item.uom || 'NOS',
            sjoNumber: entry.sjoNumber || null,
            checkedByName: entry.checkedByName || null,
          }
        });
      }
      
      return tx.qCDailyLog.findUnique({
        where: { id: log.id },
        include: { entries: { include: { qcItem: true } } }
      });
    });
    
    res.status(201).json(qcLog);
  } catch (error: any) {
    console.error('Error submitting QC report:', error);
    res.status(500).json({ error: error.message });
  }
};

export const getQCReportsHistory = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user!.userId;
    
    const reports = await prisma.qCDailyLog.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      include: {
        entries: {
          include: { qcItem: true }
        }
      }
    });
    
    res.status(200).json(reports);
  } catch (error: any) {
    console.error('Error fetching QC reports:', error);
    res.status(500).json({ error: error.message });
  }
};
