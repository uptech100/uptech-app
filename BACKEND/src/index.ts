import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth.routes';
import dashboardRoutes from './routes/dashboard.routes';
import taskRoutes from './routes/task.routes';
import qcRoutes from './routes/qc.routes';
import adminRoutes from './routes/admin.routes';
import worklogRoutes from './routes/worklog.routes';
import checklistRoutes from './routes/checklist.routes';
import ratingRoutes from './routes/rating.routes';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'UPTECH Precision Pvt Ltd Backend is running' });
});

app.get('/api', (req, res) => {
  res.json({ message: 'UPTECH Precision Pvt Ltd API is running' });
});

app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/qc', qcRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/worklog', worklogRoutes);
app.use('/api/checklists', checklistRoutes);
app.use('/api/ratings', ratingRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
