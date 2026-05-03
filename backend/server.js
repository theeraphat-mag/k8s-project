const express = require('express');
const redis = require('redis');
const cors = require('cors');
const promClient = require('prom-client');

const app = express();
app.use(cors());
app.use(express.json());

// Prometheus Metrics Setup
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Custom Metric: Total Monkey Pops
const popCounter = new promClient.Counter({
    name: 'monkey_pops_total',
    help: 'Total number of pops recorded',
    labelNames: ['username']
});
register.registerMetric(popCounter);

// Endpoint for Prometheus to scrape
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

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

    username = username.trim().toLowerCase();
    if (username.length === 0) return res.status(400).json({ error: 'Invalid username' });

    console.log(`Saving score for ${username}: ${score}`);

    // Increment Prometheus counter for monitoring
    popCounter.inc({ username: username }, parseInt(score));

    // ใช้ ZADD พร้อมตัวเลือก 'GT' (Greater Than) เพื่ออัปเดตเฉพาะคะแนนที่สูงกว่าเดิมเท่านั้น
    await client.zAdd('monkey_leaderboard', { score: parseInt(score), value: username }, { GT: true });
    
    res.json({ success: true });
});

// Get Top 5 Leaderboard
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

const PORT = 3001;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`MonkeyPop Backend running with Metrics on port ${PORT}`);
});
