const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();
const jsonPath = path.resolve(__dirname, 'database.json');

async function migrate() {
  if (!fs.existsSync(jsonPath)) {
    console.log('No JSON database found to migrate.');
    return;
  }

  const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  console.log(`Found ${data.users.length} users and ${data.transactions.length} transactions in JSON.`);

  // Migrate Users
  for (const user of data.users) {
    await prisma.user.upsert({
      where: { email: user.email },
      update: {},
      create: {
        name: user.name,
        email: user.email,
        password: user.password,
        phone: user.phone,
        accountNumber: user.accountNumber,
        balance: user.balance,
        kycStatus: user.kycStatus,
        role: user.role,
      },
    });
  }
  console.log('Users migrated.');

  // Migrate Transactions
  await prisma.transaction.deleteMany({});
  for (const tx of data.transactions) {
    await prisma.transaction.create({
      data: {
        id: tx.id,
        senderId: tx.senderId,
        receiverId: tx.receiverId,
        receiverAccountNumber: tx.receiverAccountNumber,
        amount: tx.amount,
        type: tx.type,
        status: tx.status,
        timestamp: new Date(tx.timestamp),
      },
    });
  }
  console.log('Transactions migrated.');

  await prisma.$disconnect();
}

migrate().catch((e) => {
  console.error(e);
  process.exit(1);
});
