import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';

const prisma = new PrismaClient();

async function main() {
  const raw = fs.readFileSync('C:/Users/sai/.gemini/antigravity/brain/a5cfdef3-ef27-4dd9-97e0-1b9754cc3514/scratch/aop.json', 'utf8');
  const data = JSON.parse(raw);

  console.log('Seeding AOP Targets...');
  for (const item of data.targets) {
    const category = item.category;
    for (const key of Object.keys(item)) {
      if (key !== 'category') {
        const month = key;
        const target = item[key];
        
        await prisma.aopTarget.upsert({
          where: {
            category_month: { category, month }
          },
          update: { target },
          create: { category, month, target }
        });
      }
    }
  }

  console.log('Seeding AOP Achieved...');
  // Clear achieved first so we don't have duplicates
  await prisma.aopAchieved.deleteMany();
  for (const item of data.achieved) {
    await prisma.aopAchieved.create({
      data: {
        category: item.category,
        date: new Date(item.date),
        spec: item.spec,
        quantity: item.quantity
      }
    });
  }

  console.log('Done seeding AOP data!');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
