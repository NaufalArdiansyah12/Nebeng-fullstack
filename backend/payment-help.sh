#!/bin/bash

# Quick Payment Simulation Helper
# Shortcut commands untuk testing payment

cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║            Payment Simulation - Quick Commands                 ║
╚════════════════════════════════════════════════════════════════╝

📋 LIST PENDING PAYMENTS:
   php artisan payment:pending
   ./simulate_payment.sh

🔄 WATCH MODE (auto-refresh):
   php artisan payment:pending --watch

💰 SIMULATE PAYMENT:
   php artisan payment:simulate [payment_id]
   ./simulate_payment.sh [payment_id]

🌐 API ENDPOINTS:
   GET:  http://127.0.0.1:8000/api/v1/payments/test/pending
   POST: http://127.0.0.1:8000/api/v1/payments/test/{id}/simulate

📖 FULL DOCS:
   cat PAYMENT_SIMULATION.md

EOF
