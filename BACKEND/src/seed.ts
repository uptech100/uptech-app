import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create Roles
  const roles = ['Admin', 'Worker', 'Executive 1', 'Executive 2'];
  const roleMap: Record<string, any> = {};
  
  for (const r of roles) {
    roleMap[r] = await prisma.role.upsert({
      where: { name: r },
      update: {},
      create: { 
        name: r, 
        permissions: r === 'Admin' ? { all: true } : { dashboard: true } 
      },
    });
  }

  const adminRole = roleMap['Admin'];

  // Create Departments
  const departments = [
    'Management',
    'Production',
    'Process Coordinator',
    'Quality',
    'Accounts',
    'Dispatch',
    'Sales',
    'Stores',
    'HR',
    'EA',
    'MIS',
    'Purchase'
  ];
  
  const deptMap: Record<string, any> = {};

  for (const d of departments) {
    deptMap[d] = await prisma.department.upsert({
      where: { name: d },
      update: {},
      create: { name: d },
    });
  }
  
  const adminDept = deptMap['Management'];

  // Create Admin User
  const hashedPassword = await bcrypt.hash('uptech', 10);
  
  const adminUser = await prisma.user.upsert({
    where: { mobile: '8605889356' },
    update: {
      passwordHash: hashedPassword,
      roleId: adminRole.id,
      departmentId: adminDept.id,
    },
    create: {
      employeeId: 'ADM-001',
      name: 'System Admin',
      mobile: '8605889356',
      passwordHash: hashedPassword,
      roleId: adminRole.id,
      departmentId: adminDept.id,
    },
  });

  console.log('Admin user seeded:', adminUser.mobile);

  // Seed Work Processes
  const processes = [
    'grinding', 'rough grinding', 'chapring', 'drilling', 'sandering', 'packing', 'finish grinding'
  ];
  for (const proc of processes) {
    await prisma.workProcess.upsert({
      where: { name: proc },
      update: {},
      create: { name: proc },
    });
  }

  // Seed Work Products
  const products = [
    'MAGNETIC V BLOCK', 'NON MAGNETIC V BLOCK', 'Magnetic Lifters', 'SHEET METAL LIFTER',
    'Chucks', 'Roller Bearing V Block', 'Parallel Blocks', 'SINE TABLE',
    'MAGNETIC RECTANGULAR BLOCKS', 'GRINDING VICE', 'MAGNETIC HOLDER'
  ];
  for (const prod of products) {
    await prisma.workProduct.upsert({
      where: { name: prod },
      update: {},
      create: { name: prod },
    });
  }
  
  console.log('Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
