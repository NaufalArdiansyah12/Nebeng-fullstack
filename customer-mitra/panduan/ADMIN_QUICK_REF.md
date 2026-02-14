# 🚀 Admin Panel - Quick Reference

## 🏃 Quick Start

```bash
# 1. Start Laravel backend
cd backend && php artisan serve

# 2. Start admin frontend (di terminal baru)
cd admin && ./start.sh
# atau: npm run dev

# 3. Login
# Browser: http://localhost:5173
# Email: admin@nebeng.com
# Password: password123
```

## 🔗 URLs

| Service | URL |
|---------|-----|
| Admin Panel | http://localhost:5173 |
| Laravel API | http://localhost:8000/api/admin |

## 🔑 Default Login

```
Email: admin@nebeng.com
Password: password123
```

⚠️ **Ganti password setelah login!**

## 📝 Helper Scripts

```bash
# Quick start admin panel
cd admin && ./start.sh

# Test all API endpoints
cd admin && ./test-api.sh

# Create admin account
cd backend && ./create-admin.sh
```

## 🛠️ Development

```bash
# Install dependencies
cd admin && npm install

# Run dev server
cd admin && npm run dev

# Build production
cd admin && npm run build

# Run Laravel
cd backend && php artisan serve
```

## 🧪 Test API Manual

```bash
# Login
curl -X POST http://localhost:8000/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nebeng.com","password":"password123"}'

# Get dashboard (dengan token)
curl -X GET http://localhost:8000/api/admin/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📚 Documentation

| File | Description |
|------|-------------|
| `admin/README.md` | Quick start guide |
| `admin/BACKEND_MIGRATION.md` | Migration details |
| `ADMIN_MIGRATION_COMPLETE.md` | Status & checklist |

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| 401 Unauthorized | Logout & login lagi |
| CORS Error | Check `backend/config/cors.php` |
| 500 Error | Check `backend/storage/logs/laravel.log` |
| Connection refused | Start Laravel backend |

## ✅ Status

✅ **Production Ready**
- Backend: Laravel 11
- Frontend: React + TypeScript + Vite
- Total Endpoints: 36 (All Ready)

---

**Last Updated:** February 14, 2026
