#!/bin/bash

# 👤 Create Default Admin Account
# Script ini akan membuat default admin account jika belum ada

echo "👤 CREATE DEFAULT ADMIN ACCOUNT"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in backend directory
if [ ! -f "artisan" ]; then
    echo -e "${RED}❌ Error: artisan not found!${NC}"
    echo "Please run this script from the backend directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Running from backend directory"
echo ""

# Create admin using tinker
echo "📝 Creating admin account..."
echo ""

php artisan tinker --execute="
// Check if admin already exists
\$existingAdmin = App\Models\User::where('email', 'admin@nebeng.com')->first();

if (\$existingAdmin) {
    echo '⚠️  Admin account already exists!' . PHP_EOL;
    echo 'Email: ' . \$existingAdmin->email . PHP_EOL;
    echo 'Name: ' . \$existingAdmin->name . PHP_EOL;
    echo 'Role: ' . \$existingAdmin->role . PHP_EOL;
    echo 'Status: ' . \$existingAdmin->status . PHP_EOL;
    echo PHP_EOL;
    echo '💡 To reset password, use:' . PHP_EOL;
    echo '   php artisan tinker --execute=\"\$user = App\Models\User::where(\\\"email\\\", \\\"admin@nebeng.com\\\")->first(); \$user->password = bcrypt(\\\"password123\\\"); \$user->save(); echo \\\"Password reset!\\\";\"' . PHP_EOL;
} else {
    // Create new admin
    \$admin = new App\Models\User();
    \$admin->name = 'Administrator';
    \$admin->email = 'admin@nebeng.com';
    \$admin->password = bcrypt('password123');
    \$admin->role = 'admin';
    \$admin->status = 'active';
    \$admin->phone_verified = true;
    \$admin->save();
    
    echo '✅ Admin account created successfully!' . PHP_EOL;
    echo PHP_EOL;
    echo '📧 Email: admin@nebeng.com' . PHP_EOL;
    echo '🔑 Password: password123' . PHP_EOL;
    echo PHP_EOL;
    echo '⚠️  IMPORTANT: Change password after first login!' . PHP_EOL;
}
"

echo ""
echo "================================"
echo -e "${GREEN}✅ Done!${NC}"
echo "================================"
