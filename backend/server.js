const express = require('express');
const redis = require('redis');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Redis setup
const client = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379'
});
client.on('error', err => console.error('Redis Client Error', err));
client.connect();

// Save or Update Score
app.post('/api/score', async (req, res) => {
    let { username, score } = req.body;
    if (!username || score === undefined) return res.status(400).json({ error: 'Invalid data' });

    username = username.trim().toLowerCase(); // ลบช่องว่างและทำให้เป็นตัวพิมพ์เล็กทั้งหมดเพื่อกันชื่อซ้ำแบบ Monkey vs monkey
    if (username.length === 0) return res.status(400).json({ error: 'Invalid username' });

    console.log(`Saving score for ${username}: ${score}`);

    // ใช้ ZADD พร้อมตัวเลือก 'GT' (Greater Than) เพื่ออัปเดตเฉพาะคะแนนที่สูงกว่าเดิมเท่านั้น
    await client.zAdd('monkey_leaderboard', { score: parseInt(score), value: username }, { GT: true });
    
    res.json({ success: true });
});

// Get Top 5 Leaderboard (ตามที่หน้าเว็บคุณขอ Top 5)
app.get('/api/leaderboard', async (req, res) => {
    try {
        const rawList = await client.zRangeWithScores('monkey_leaderboard', 0, 4, { REV: true });
        
        const leaderboard = rawList.map(item => ({
            username: item.value,
            score: item.score
        }));

        res.json(leaderboard);
    } catch (e) {
        res.status(500).json({ error: 'Database error' });
    }
});

const PORT = 3001; // เปลี่ยนเป็น 3001 ตามหน้า Frontend ของคุณ
app.listen(PORT, '0.0.0.0', () => {
    console.log(`MonkeyPop Backend running on port ${PORT}`);
});
