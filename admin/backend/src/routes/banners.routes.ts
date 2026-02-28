import express from 'express';
import path from 'path';
import fs from 'fs/promises';
import type { Request, Response } from 'express';
import { pool } from '../db';

const router = express.Router();

function isDataUrl(str?: string) {
  return typeof str === 'string' && str.startsWith('data:');
}

async function saveDataUrlToFile(dataUrl: string, req: Request) {
  const match = dataUrl.match(/^data:(image\/[^;]+);base64,(.+)$/);
  if (!match) return null;
  const mime = match[1];
  const b64 = match[2];
  const ext = mime.split('/')[1].split('+')[0] || 'png';

  // Save to admin uploads folder
  const adminUploadsDir = path.join(process.cwd(), 'public', 'uploads', 'banners');
  await fs.mkdir(adminUploadsDir, { recursive: true });
  const filename = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
  const adminFilepath = path.join(adminUploadsDir, filename);
  const buffer = Buffer.from(b64, 'base64');
  await fs.writeFile(adminFilepath, buffer);

  // Also save into Laravel backend public folder so Laravel can serve images without admin running
  try {
    const backendUploadsDir = path.join(process.cwd(), '..', '..', 'backend', 'public', 'uploads', 'banners');
    await fs.mkdir(backendUploadsDir, { recursive: true });
    const backendFilepath = path.join(backendUploadsDir, filename);
    await fs.writeFile(backendFilepath, buffer).catch(() => {});
  } catch (e) {
    // ignore errors writing to backend folder
  }

  // Prefer BACKEND_PUBLIC_URL if available (Laravel public URL), otherwise fall back to ADMIN_PUBLIC_URL or request host
  const backendPublic = process.env.BACKEND_PUBLIC_URL && process.env.BACKEND_PUBLIC_URL.length > 0
    ? process.env.BACKEND_PUBLIC_URL.replace(/\/+$/,'')
    : null;
  const adminPublic = process.env.ADMIN_PUBLIC_URL && process.env.ADMIN_PUBLIC_URL.length > 0
    ? process.env.ADMIN_PUBLIC_URL.replace(/\/+$/,'')
    : `${req.protocol}://${req.get('host')}`;

  const publicBase = backendPublic || adminPublic;
  return `${publicBase}/uploads/banners/${filename}`;
}

// GET / - list banners (optional ?position=home)
router.get('/', async (req: Request, res: Response) => {
  try {
    const position = req.query.position ? String(req.query.position) : undefined;
    let sql = 'SELECT * FROM banners';
    const params: any[] = [];
    if (position) {
      sql += ' WHERE position = ?';
      params.push(position);
    }
    sql += ' ORDER BY `order` ASC, id DESC';
    const [rows]: any = await pool.query(sql, params);
    res.json(rows);
  } catch (err: any) {
    console.error('GET /banners error', err);
    res.status(500).json({ error: err.message || 'Server error' });
  }
});

// GET /:id
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const [rows]: any = await pool.query('SELECT * FROM banners WHERE id = ?', [id]);
    if (!rows || rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err: any) {
    console.error('GET /banners/:id error', err);
    res.status(500).json({ error: err.message || 'Server error' });
  }
});

// POST / - create banner
router.post('/', async (req: Request, res: Response) => {
  try {
    const { title = null, image_url = null, is_active = true, position = 'home', order = 0 } = req.body || {};
    let imageUrlToSave: string | null = image_url;
    if (isDataUrl(image_url)) {
      const saved = await saveDataUrlToFile(image_url, req);
      if (saved) imageUrlToSave = saved;
    }
    const [result]: any = await pool.execute(
      'INSERT INTO banners (title, image_url, is_active, position, `order`, created_at, updated_at) VALUES (?, ?, ?, ?, ?, NOW(), NOW())',
      [title, imageUrlToSave, is_active ? 1 : 0, position, order]
    );
    const insertId = result.insertId;
    const [rows]: any = await pool.query('SELECT * FROM banners WHERE id = ?', [insertId]);
    res.json(rows[0]);
  } catch (err: any) {
    console.error('POST /banners error', err);
    res.status(500).json({ error: err.message || 'Server error' });
  }
});

// PUT /:id - update banner
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { title, image_url, is_active, position, order } = req.body || {};
    // Fetch existing
    const [existingRows]: any = await pool.query('SELECT * FROM banners WHERE id = ?', [id]);
    if (!existingRows || existingRows.length === 0) return res.status(404).json({ error: 'Not found' });
    const existing = existingRows[0];

    let imageUrlToSave = existing.image_url;
    if (image_url && isDataUrl(image_url)) {
      const saved = await saveDataUrlToFile(image_url, req);
      if (saved) imageUrlToSave = saved;
    } else if (typeof image_url === 'string' && image_url.length > 0) {
      imageUrlToSave = image_url;
    }

    await pool.execute(
      'UPDATE banners SET title = ?, image_url = ?, is_active = ?, position = ?, `order` = ?, updated_at = NOW() WHERE id = ?',
      [title ?? existing.title, imageUrlToSave, typeof is_active === 'undefined' ? existing.is_active : (is_active ? 1 : 0), position ?? existing.position, typeof order === 'undefined' ? existing.order : order, id]
    );
    const [rows]: any = await pool.query('SELECT * FROM banners WHERE id = ?', [id]);
    res.json(rows[0]);
  } catch (err: any) {
    console.error('PUT /banners/:id error', err);
    res.status(500).json({ error: err.message || 'Server error' });
  }
});

// DELETE /:id
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const [rows]: any = await pool.query('SELECT * FROM banners WHERE id = ?', [id]);
    if (!rows || rows.length === 0) return res.status(404).json({ error: 'Not found' });
    const banner = rows[0];
    // If image is stored in uploads folder, try to remove file
    if (banner.image_url && typeof banner.image_url === 'string' && banner.image_url.includes('/uploads/banners/')) {
      try {
        const parts = banner.image_url.split('/uploads/banners/');
        const filename = parts[1];
        // remove from admin uploads
        const adminPath = path.join(process.cwd(), 'public', 'uploads', 'banners', filename);
        await fs.unlink(adminPath).catch(() => {});
        // remove from backend (Laravel) uploads if present
        const backendPath = path.join(process.cwd(), '..', '..', 'backend', 'public', 'uploads', 'banners', filename);
        await fs.unlink(backendPath).catch(() => {});
      } catch (e) {
        // ignore file deletion errors
      }
    }
    await pool.execute('DELETE FROM banners WHERE id = ?', [id]);
    res.json({ success: true });
  } catch (err: any) {
    console.error('DELETE /banners/:id error', err);
    res.status(500).json({ error: err.message || 'Server error' });
  }
});

export default router;
