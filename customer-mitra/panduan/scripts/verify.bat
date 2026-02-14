@echo off
REM Verification script untuk memastikan setup benar

echo.
echo 🔍 Nebeng Admin - Backend Verification
echo ======================================
echo.

REM Check Node.js
echo Checking Node.js...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo   ✅ Node.js !NODE_VERSION! found
) else (
    echo   ❌ Node.js not found
)

REM Check npm
echo Checking npm...
npm --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo   ✅ npm !NPM_VERSION! found
) else (
    echo   ❌ npm not found
)

REM Check backend files
echo Checking backend files...

set "backend_files=^
backend/server.ts ^
backend/package.json ^
backend/tsconfig.json ^
backend/.env.example ^
backend/database/schema.sql ^
backend/src/routes/admin.routes.ts ^
backend/src/routes/customer.routes.ts ^
backend/src/routes/mitra.routes.ts ^
backend/src/routes/pesanan.routes.ts ^
backend/src/routes/laporan.routes.ts ^
backend/src/routes/refund.routes.ts"

for %%f in (%backend_files%) do (
    if exist "%%f" (
        echo   ✅ %%f
    ) else (
        echo   ❌ %%f - MISSING!
    )
)

REM Check API service
echo Checking API service...
if exist "src/services/api.ts" (
    echo   ✅ src/services/api.ts
) else (
    echo   ❌ src/services/api.ts - MISSING!
)

REM Check documentation
echo Checking documentation...

set "docs=^
SETUP_GUIDE.md ^
INTEGRATION_GUIDE.md ^
DATABASE_SCHEMA.md ^
README_BACKEND.md ^
COMPLETION_CHECKLIST.md ^
START_HERE.md ^
TROUBLESHOOTING.md"

for %%d in (%docs%) do (
    if exist "%%d" (
        echo   ✅ %%d
    ) else (
        echo   ❌ %%d - MISSING!
    )
)

echo.
echo ✅ Verification Complete!
echo.
echo Next steps:
echo 1. cd backend ^&^& npm install
echo 2. copy .env.example .env
echo 3. mysql -u root -p ^< database\schema.sql
echo 4. npm run dev
echo.
pause
