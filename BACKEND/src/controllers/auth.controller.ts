import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

export const login = async (req: Request, res: Response) => {
  try {
    const { mobile, password } = req.body;

    if (!mobile || !password) {
      return res.status(400).json({ message: 'Mobile number and password are required' });
    }

    const user = await prisma.user.findUnique({
      where: { mobile },
      include: { role: true, department: true },
    });

    if (!user) {
      return res.status(401).json({ message: 'Invalid mobile number or password' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid mobile number or password' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role.name, deptId: user.departmentId },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        employeeId: user.employeeId,
        name: user.name,
        role: user.role.name,
        department: user.department.name,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
