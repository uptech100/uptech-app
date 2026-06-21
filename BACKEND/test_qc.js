const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const user = await prisma.user.findFirst();
    if (!user) throw new Error("No user found");
    
    // Simulate what the controller does:
    const targetDate = new Date();
    
    const qcLog = await prisma.$transaction(async (tx) => {
      const log = await tx.qCDailyLog.upsert({
        where: {
          userId_date: {
            userId: user.id,
            date: targetDate,
          }
        },
        update: {},
        create: {
          userId: user.id,
          date: targetDate,
        }
      });
      
      let item = await tx.qCItem.findUnique({ where: { itemCode: 'TEST1234' } });
      if (!item) {
        item = await tx.qCItem.create({
          data: {
            itemCode: 'TEST1234',
            category: 'General',
            description: 'Test Item',
            uom: 'NOS',
          }
        });
      }
      
      await tx.qCReportEntry.create({
        data: {
          qcLogId: log.id,
          qcItemId: item.id,
          process: 'Finish Checking',
          quantity: 10,
        }
      });
      
      return log;
    });
    
    console.log("Success:", qcLog);
  } catch (e) {
    console.error("Error:", e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
