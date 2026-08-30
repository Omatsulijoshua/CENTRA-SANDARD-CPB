const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Interface for the existing server code
const db = {
    get: (query, params, callback) => {
        if (query.includes('SELECT * FROM users WHERE email = ?')) {
            prisma.user.findUnique({ where: { email: params[0] } })
                .then(user => callback(null, user))
                .catch(err => callback(err, null));
        } else if (query.includes('SELECT id, name, email, phone, accountNumber, balance, kycStatus FROM users WHERE id = ?')) {
            prisma.user.findUnique({ where: { id: params[0] } })
                .then(user => callback(null, user))
                .catch(err => callback(err, null));
        } else if (query.includes('SELECT role FROM users WHERE id = ?')) {
            prisma.user.findUnique({ where: { id: params[0] }, select: { role: true } })
                .then(user => callback(null, user))
                .catch(err => callback(err, null));
        } else if (query.includes('SELECT name FROM users WHERE accountNumber = ?')) {
            prisma.user.findUnique({ where: { accountNumber: params[0] }, select: { name: true } })
                .then(user => callback(null, user))
                .catch(err => callback(err, null));
        }
    },

    all: (query, params, callback) => {
        if (typeof params === 'function') {
            callback = params;
            params = [];
        }

        if (query.includes('SELECT t.*, s.name as senderName, r.name as receiverName')) {
            prisma.transaction.findMany({
                include: { sender: { select: { name: true } }, receiver: { select: { name: true } } },
                orderBy: { timestamp: 'desc' }
            }).then(txs => {
                const formatted = txs.map(t => ({
                    ...t,
                    senderName: t.sender?.name,
                    receiverName: t.receiver?.name
                }));
                callback(null, formatted);
            }).catch(err => callback(err, null));
        } else if (query.includes('SELECT id, name, email, phone, accountNumber, balance, kycStatus, role FROM users')) {
            prisma.user.findMany()
                .then(users => callback(null, users))
                .catch(err => callback(err, null));
        } else if (query.includes('SELECT * FROM transactions WHERE senderId = ? OR receiverId = ?')) {
            prisma.transaction.findMany({
                where: { OR: [{ senderId: params[0] }, { receiverId: params[1] }] },
                orderBy: { timestamp: 'desc' }
            }).then(txs => callback(null, txs))
                .catch(err => callback(err, null));
        } else if (query.includes('SELECT DATE(timestamp) as date')) {
            // Stats activity - simple mock or aggregate
            callback(null, []);
        }
    },

    run: (query, params, callback) => {
        if (query.includes('INSERT INTO users')) {
            prisma.user.create({
                data: {
                    name: params[0],
                    email: params[1],
                    password: params[2],
                    phone: params[3],
                    accountNumber: params[4],
                    balance: 10000.0,
                    kycStatus: 'pending',
                    role: 'user'
                }
            }).then(user => {
                if (callback) callback.call({ lastID: user.id }, null);
            }).catch(err => callback && callback(err));
        } else if (query.includes('UPDATE users SET balance = balance - ?')) {
            prisma.user.update({
                where: { id: params[1] },
                data: { balance: { decrement: params[0] } }
            }).then(() => callback && callback(null))
                .catch(err => callback && callback(err));
        } else if (query.includes('UPDATE users SET balance = balance + ?')) {
            prisma.user.update({
                where: { id: params[1] },
                data: { balance: { increment: params[0] } }
            }).then(() => callback && callback(null))
                .catch(err => callback && callback(err));
        } else if (query.includes('INSERT INTO transactions')) {
            prisma.transaction.create({
                data: {
                    senderId: params[0],
                    receiverId: params[1],
                    receiverAccountNumber: params[2],
                    amount: params[3],
                    type: params[4],
                    status: 'completed'
                }
            }).then(tx => {
                if (callback) callback.call({ lastID: tx.id }, null);
            }).catch(err => callback && callback(err));
        } else if (query.includes('UPDATE users SET kycStatus = ?')) {
            prisma.user.update({
                where: { id: parseInt(params[1]) },
                data: { kycStatus: params[0] }
            }).then(() => callback && callback(null))
                .catch(err => callback && callback(err));
        } else if (query.includes('UPDATE users SET balance = ?')) {
            prisma.user.update({
                where: { id: parseInt(params[1]) },
                data: { balance: params[0] }
            }).then(() => callback && callback(null))
                .catch(err => callback && callback(err));
        }
    },

    // Aggregates for stats
    getStats: async () => {
        const totalUsers = await prisma.user.count();
        const totalDeposits = await prisma.user.aggregate({ _sum: { balance: true } });
        const totalTransactions = await prisma.transaction.count();
        const activity = await prisma.$queryRaw`SELECT date(timestamp) as date, count(*) as count FROM Transaction GROUP BY date(timestamp) LIMIT 7`;
        
        return {
            totalUsers,
            totalDeposits: totalDeposits._sum.balance || 0,
            totalTransactions,
            activity
        };
    }
};

module.exports = db;
