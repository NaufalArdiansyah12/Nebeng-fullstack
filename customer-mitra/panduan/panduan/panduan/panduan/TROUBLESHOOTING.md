# 🔧 Troubleshooting Guide

## Backend Connection Issues

### ❌ "Cannot connect to database"

**Solutions:**
1. Pastikan MySQL running
2. Check username & password di `.env` benar
3. Check database `nebeng_admin` sudah dibuat
4. Cek di MySQL CLI:
   ```bash
   mysql -u root -p
   SHOW DATABASES;
   USE nebeng_admin;
   SHOW TABLES;
   ```

### ❌ "Port 3001 already in use"

**Solutions:**
```bash
# Find what's using port 3001
netstat -ano | findstr :3001

# Kill the process (Windows)
taskkill /PID <PID_NUMBER> /F

# Or use different port
PORT=3002 npm run dev
```

### ❌ "Error: listen EADDRINUSE"

Same as above, port sudah terpakai.

---

## Database Issues

### ❌ "Unknown database 'nebeng_admin'"

**Solution:**
```bash
# Run schema.sql lagi
mysql -u root -p < backend/database/schema.sql

# Atau manual di MySQL:
mysql -u root -p
CREATE DATABASE nebeng_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### ❌ "Access denied for user"

**Solution:**
1. Check username di `.env`
2. Check password benar
3. Buat user baru di MySQL:
   ```bash
   mysql -u root -p
   CREATE USER 'nebeng'@'localhost' IDENTIFIED BY 'password123';
   GRANT ALL PRIVILEGES ON nebeng_admin.* TO 'nebeng'@'localhost';
   FLUSH PRIVILEGES;
   ```
4. Update `.env`:
   ```
   DB_USER=nebeng
   DB_PASSWORD=password123
   ```

### ❌ "Syntax error in schema.sql"

**Solution:**
1. Make sure file tidak corrupted
2. Copy dari `backend/database/schema.sql` lagi
3. Atau run satu table dulu untuk test

---

## Frontend Connection Issues

### ❌ "CORS error" atau "Network request failed"

**Solution:**
1. Check backend running: `http://localhost:3001/api/health`
2. Check `.env` memiliki: `VITE_API_URL=http://localhost:3001/api`
3. Reload browser (Ctrl+F5)

### ❌ "404 Not Found" di API call

**Solution:**
1. Check endpoint URL benar
2. Check backend running
3. Check route file sudah dibuat
4. Check di browser console untuk actual URL

### ❌ "Cannot GET /api/customers"

**Solution:**
1. Backend tidak running
2. Port wrong
3. Route tidak ada

Run backend dengan debug:
```bash
npm run dev
# Lihat logs di console
```

---

## Installation Issues

### ❌ "npm: command not found"

**Solution:**
- Install Node.js dari nodejs.org
- Verifikasi: `node --version`

### ❌ "dependencies not installed"

**Solution:**
```bash
cd backend
rm -rf node_modules
npm install
```

### ❌ "TypeScript compilation error"

**Solution:**
```bash
cd backend
npx tsc --version
npm install
npm run build  # Test build
```

---

## MySQL Specific Issues

### ❌ "MySQL command not found"

**Solution:**
- Add MySQL to PATH environment variable
- Windows: `C:\Program Files\MySQL\MySQL Server 8.0\bin`
- Or use full path: `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql`

### ❌ "Access denied (password required)"

**Solution:**
```bash
# With password prompt
mysql -u root -p

# Or provide password
mysql -u root -pYOUR_PASSWORD < backend/database/schema.sql
```

### ❌ "Connection timeout"

**Solution:**
1. Check MySQL service running (Services.msc)
2. Check connection string di `.env`
3. Try localhost instead of 127.0.0.1

---

## Development Issues

### ❌ "Hot reload not working"

**Solution:**
```bash
# Kill old process
npm run dev
# Or
Ctrl+C then npm run dev
```

### ❌ "Changes not reflected"

**Solution:**
1. Check file saved
2. Reload browser
3. Restart backend: Ctrl+C, then npm run dev

### ❌ "API returns error"

**Check the error in console:**
1. Backend console untuk server error
2. Browser console untuk client error
3. Network tab untuk request/response

---

## Common API Errors

### ❌ 400 Bad Request
- Missing required fields
- Wrong data type
- Invalid JSON

**Fix:** Check API docs, validate request data

### ❌ 404 Not Found
- Resource tidak ada
- Wrong URL
- Typo di endpoint

**Fix:** Check resource ID, check endpoint

### ❌ 500 Internal Server Error
- Backend error
- Database connection lost
- Invalid query

**Fix:** Check backend console, check database connection

---

## Performance Issues

### ❌ "API calls very slow"

**Solution:**
1. Check MySQL performance
2. Check indexes created
3. Check network latency
4. Consider pagination:
   ```bash
   GET /api/customers?page=1&limit=10
   ```

### ❌ "High memory usage"

**Solution:**
1. Check for memory leaks
2. Limit connection pool size
3. Add pagination
4. Clear old logs

---

## Testing Endpoints

### Quick test dengan cURL

```bash
# Get all customers
curl http://localhost:3001/api/customers

# Get one customer
curl http://localhost:3001/api/customers/1

# Create customer
curl -X POST http://localhost:3001/api/customers \
  -H "Content-Type: application/json" \
  -d '{"kode":"CST999","nama":"Test"}'

# Block customer
curl -X POST http://localhost:3001/api/customers/1/block
```

### Atau gunakan Postman/Thunder Client
1. Download extension di VS Code
2. Create new request
3. Set method (GET, POST, PUT, DELETE)
4. Enter URL
5. Add body (untuk POST/PUT)
6. Send

---

## Debugging Tips

### 1. Enable Verbose Logging
```bash
# Edit server.ts, tambahkan:
console.log('Request:', req.method, req.url);
```

### 2. Check Database Directly
```bash
mysql -u root -p
USE nebeng_admin;
SELECT * FROM customer;
```

### 3. Monitor Requests
- Open DevTools (F12)
- Go to Network tab
- Make API call
- See request/response

### 4. Check Environment Variables
```bash
# Linux/Mac
echo $DB_HOST
echo $DB_USER

# Windows (PowerShell)
$env:DB_HOST
$env:DB_USER
```

---

## Reset Everything

Jika semua error, reset dari awal:

```bash
# 1. Drop database
mysql -u root -p
DROP DATABASE nebeng_admin;
EXIT;

# 2. Run schema lagi
mysql -u root -p < backend/database/schema.sql

# 3. Restart backend
cd backend
npm run dev
```

---

## Getting Help

1. **Check logs** - Backend console & browser console
2. **Check docs** - SETUP_GUIDE.md, DATABASE_SCHEMA.md
3. **Google the error** - Usually others had same issue
4. **Test API** - Use Postman/cURL untuk isolate issue
5. **Check MySQL** - Connect directly to verify data

---

## Quick Checklist

- [ ] MySQL running? (`services.msc` or `brew services list`)
- [ ] Database created? (`SHOW DATABASES;`)
- [ ] Tables exist? (`USE nebeng_admin; SHOW TABLES;`)
- [ ] .env configured? (DB credentials correct)
- [ ] Node dependencies installed? (`npm install` in backend)
- [ ] Backend running? (`npm run dev`)
- [ ] Can access health check? (`http://localhost:3001/api/health`)
- [ ] VITE_API_URL set in .env?
- [ ] Frontend can reach API? (Check Network tab)

---

**Stuck?** Check the actual error message, google it, dan follow the solutions di atas!
