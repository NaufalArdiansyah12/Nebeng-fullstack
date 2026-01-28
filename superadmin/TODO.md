# Database Table Fixes for Backend Routes

## Issues Identified
1. **verifikasi.routes.ts**: Queries non-existent `verifikasi_ktp_mitras` and `verifikasi_ktp_customers` tables. Should query `mitra` and `customer` tables for pending verification statuses.
2. **pesanan.routes.ts**: GET / queries `booking_*` tables instead of `pesanan` table.
3. **customer.routes.ts**: GET / queries `users` table instead of `customer` table.
4. **mitra.routes.ts**: GET / queries `users` table instead of `mitra` table.

## Plan
- [ ] Fix verifikasi.routes.ts to query customer/mitra tables for verification data
- [ ] Fix pesanan.routes.ts GET / to query pesanan table instead of booking tables
- [ ] Fix customer.routes.ts GET / to query customer table
- [ ] Fix mitra.routes.ts GET / to query mitra table
- [ ] Test all routes work with correct data retrieval

## Verification Logic
- Pending verification: status = 'PENGAJUAN'
- Approved: status = 'TERVERIFIKASI'
- Rejected: status = 'DITOLAK'
- Blocked: status = 'DIBLOCK'
