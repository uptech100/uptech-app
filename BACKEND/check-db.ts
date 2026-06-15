const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const users = await prisma.user.findMany({ include: { role: true, department: true } });
  console.log('Users found:', users.length);
  users.forEach(u => {
    console.log(`  - ${u.employeeId} | ${u.name} | ${u.role.name} | ${u.department.name}`);
  });
  await prisma['$disconnect']();
}

check().catch(e => { console.error(e); process.exit(1); });
