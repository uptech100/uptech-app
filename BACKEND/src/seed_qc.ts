import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const categories = [
    'MAGNETIC V BLOCK',
    'NON MAGNETIC V BLOCK',
    'Magnetic Lifters',
    'SHEET METAL LIFTER',
    'Chucks',
    'Roller Bearing V Block',
    'Parallel Blocks',
    'SINE TABLE',
    'MAGNETIC RECTANGULAR BLOCKS',
    'GRINDING VICE',
    'MAGNETIC HOLDER',
    'OTHERS'
  ];

  const items = [
    { itemCode: 'PMLUL80500N', description: 'PERMANENT MAGNETIC LIFTER (1:3.5T) 100 KG-90X65X85 MM', uom: 'NOS', category: 'Magnetic Lifters', hsnCode: '85051900' },
    { itemCode: 'PMLUL80501N', description: 'PERMANENT MAGNETIC LIFTER (1:3.5T) 200 KG-170X85X105 MM', uom: 'NOS', category: 'Magnetic Lifters', hsnCode: '85051900' },
    { itemCode: 'PMLUL80502N', description: 'PERMANENT MAGNETIC LIFTER (1:3.5T) 250 KG-170X85X105 MM', uom: 'NOS', category: 'Magnetic Lifters', hsnCode: '85051900' },
    { itemCode: 'MVB101', description: 'MAGNETIC V BLOCK 50X50X50', uom: 'NOS', category: 'MAGNETIC V BLOCK', hsnCode: '8505' },
    { itemCode: 'MVB102', description: 'MAGNETIC V BLOCK 100X100X100', uom: 'NOS', category: 'MAGNETIC V BLOCK', hsnCode: '8505' },
    { itemCode: 'NMVB201', description: 'NON MAGNETIC V BLOCK 50X50', uom: 'NOS', category: 'NON MAGNETIC V BLOCK', hsnCode: '8505' },
    { itemCode: 'SML301', description: 'SHEET METAL LIFTER 500KG', uom: 'NOS', category: 'SHEET METAL LIFTER', hsnCode: '8505' },
    { itemCode: 'CHK401', description: 'MAGNETIC CHUCK 150X300', uom: 'NOS', category: 'Chucks', hsnCode: '8505' },
    { itemCode: 'RBV501', description: 'ROLLER BEARING V BLOCK', uom: 'NOS', category: 'Roller Bearing V Block', hsnCode: '8505' },
    { itemCode: 'PB601', description: 'PARALLEL BLOCKS SET', uom: 'SET', category: 'Parallel Blocks', hsnCode: '8505' },
    { itemCode: 'ST701', description: 'SINE TABLE 150X300', uom: 'NOS', category: 'SINE TABLE', hsnCode: '8505' },
    { itemCode: 'GV801', description: 'GRINDING VICE 100MM', uom: 'NOS', category: 'GRINDING VICE', hsnCode: '8505' },
  ];

  for (const item of items) {
    await prisma.qCItem.upsert({
      where: { itemCode: item.itemCode },
      update: {},
      create: item,
    });
  }

  console.log('QC Items seeded successfully.');
}

main().catch(console.error).finally(() => prisma.$disconnect());
