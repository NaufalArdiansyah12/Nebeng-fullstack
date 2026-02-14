@echo off
REM Nebeng Admin - Quick Setup Script for Windows
REM This script automates the setup process

echo.
echo 🚀 Nebeng Admin Backend Setup
echo ==============================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js 18+ first.
    pause
    exit /b 1
)

echo ✅ Node.js found:
node --version

echo.
echo Step 1: Setup Backend Dependencies
echo -----------------------------------
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed

echo.
echo Step 2: Create .env file
echo ------------------------
if not exist .env (
    copy .env.example .env
    echo ✅ .env file created from template
    echo ⚠️  Please edit backend\.env with your MySQL credentials
) else (
    echo ℹ️  .env already exists, skipping...
)

echo.
echo Step 3: Database Setup
echo ----------------------
echo Would you like to setup the MySQL database now?
set /p db_setup="Setup database? (y/n): "

if /i "%db_setup%"=="y" (
    echo.
    set /p db_user="Enter MySQL user (default: root): "
    if "%db_user%"=="" set db_user=root
    
    mysql -u %db_user% -p < database\schema.sql
    if %errorlevel% equ 0 (
        echo ✅ Database setup completed
    ) else (
        echo ❌ Database setup failed
        echo Make sure MySQL is installed and running
    )
) else (
    echo ℹ️  Skipping database setup
    echo To setup later, run:
    echo   mysql -u root -p ^< backend\database\schema.sql
)

echo.
echo ✅ Setup Complete!
echo ==================
echo.
echo Next steps:
echo 1. Edit backend\.env with your database credentials
echo 2. Run: cd backend ^&^& npm run dev
echo 3. Backend will start at http://localhost:3001
echo.
echo For frontend:
echo 1. Make sure .env has VITE_API_URL=http://localhost:3001/api
echo 2. Run: npm run dev (in root directory)
echo.
echo 📖 See README_BACKEND.md for more information
echo.
pause
