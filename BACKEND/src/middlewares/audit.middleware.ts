import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const auditLog = async (req: Request, res: Response, next: NextFunction) => {
  const originalSend = res.send;

  res.send = function (body: any): Response {
    res.send = originalSend;

    // Log the action asynchronously after the response is sent
    const logAction = async () => {
      try {
        const userId = (req as any).user?.userId;
        const action = `${req.method} ${req.originalUrl}`;
        const details = {
          body: req.body,
          query: req.query,
          params: req.params,
          statusCode: res.statusCode,
        };

        await prisma.auditLog.create({
          data: {
            action,
            userId,
            details,
          },
        });
      } catch (error) {
        console.error('Failed to write audit log:', error);
      }
    };

    logAction();
    return res.send(body);
  };

  next();
};
