const express = require('express');
const path = require('path');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('MONGO_URL environment variable is required');
  process.exit(1);
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db;
let mongoClient;

async function connectMongo() {
  mongoClient = new MongoClient(MONGO_URL, {
    serverSelectionTimeoutMS: 5000,
  });
  await mongoClient.connect();
  db = mongoClient.db(); // uses db name from the connection string (emidb)
  console.log('Connected to MongoDB');
}

// Retry connecting so the app doesn't crash if Mongo isn't ready yet
async function connectWithRetry() {
  while (true) {
    try {
      await connectMongo();
      break;
    } catch (err) {
      console.error('MongoDB connection failed, retrying in 3s...', err.message);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
}
connectWithRetry();

function isPositiveNumber(val) {
  return typeof val === 'number' && isFinite(val) && val > 0;
}

function calculateEMI(P, annualRatePercent, n) {
  const r = annualRatePercent / 12 / 100;
  let emi;
  if (r === 0) {
    emi = P / n;
  } else {
    emi = (P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
  }
  const totalPayment = emi * n;
  const totalInterest = totalPayment - P;
  return {
    emi: Number(emi.toFixed(2)),
    totalPayment: Number(totalPayment.toFixed(2)),
    totalInterest: Number(totalInterest.toFixed(2)),
  };
}

// POST /api/emi
app.post('/api/emi', async (req, res) => {
  const { principal, rate, months } = req.body;

  const P = Number(principal);
  const rateNum = Number(rate);
  const n = Number(months);

  if (!isPositiveNumber(P) || !isPositiveNumber(rateNum) || !isPositiveNumber(n) || !Number.isInteger(n)) {
    return res.status(400).json({
      error: 'Invalid input: principal, rate and months must be positive numbers, months must be a whole number.',
    });
  }

  const { emi, totalPayment, totalInterest } = calculateEMI(P, rateNum, n);
  const servedBy = process.env.HOSTNAME || 'unknown';

  const doc = {
    principal: P,
    rate: rateNum,
    months: n,
    emi,
    servedBy,
    createdAt: new Date(),
  };

  try {
    await db.collection('calculations').insertOne(doc);
  } catch (err) {
    console.error('Failed to save calculation:', err.message);
    return res.status(503).json({ error: 'Database unavailable, could not save calculation.' });
  }

  res.json({
    emi,
    totalPayment,
    totalInterest,
    servedBy,
  });
});

// GET /api/history
app.get('/api/history', async (req, res) => {
  try {
    const history = await db
      .collection('calculations')
      .find({})
      .sort({ createdAt: -1 })
      .limit(10)
      .toArray();
    res.json(history);
  } catch (err) {
    console.error('Failed to fetch history:', err.message);
    res.status(503).json({ error: 'Database unavailable.' });
  }
});

// GET /health -- readiness probe target
app.get('/health', async (req, res) => {
  try {
    if (!db) throw new Error('DB not connected yet');
    await db.command({ ping: 1 });
    res.status(200).json({ status: 'ok' });
  } catch (err) {
    res.status(503).json({ status: 'unavailable', error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`EMI Calculator listening on port ${PORT}`);
});