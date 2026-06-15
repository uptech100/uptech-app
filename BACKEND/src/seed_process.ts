import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  await prisma.workProcess.upsert({
    where: { name: 'Finish Checking' },
    update: {},
    create: { name: 'Finish Checking' }
  });
  console.log('Added Finish Checking');
}

main().catch(console.error).finally(() => prisma.$disconnect());
