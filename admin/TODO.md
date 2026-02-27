# TODO: Add Tanggapan (Response) Functionality to Laporan

## Plan
1. [x] Confirm plan with user
2. [x] Add `respondLaporan` API method in `src/services/api.ts`
3. [x] Add backend endpoint to respond to laporan in `backend/src/routes/laporan.routes.ts`
4. [x] Add `tanggapan` field to `src/contexts/LaporanContext.tsx`
5. [x] Update `src/pages/DetailLaporan.tsx` UI for response input and save functionality
6. [x] Test the implementation

## Summary of Changes Made:

### 1. Frontend API (`src/services/api.ts`)
- Added `respond` method to `laporanApi` to call PATCH `/laporan/:id/respond`

### 2. Backend Route (`backend/src/routes/laporan.routes.ts`)
- Added new endpoint `PATCH /:id/respond` to save tanggapan and optionally update status to "SELESAI"

### 3. Laporan Context (`src/contexts/LaporanContext.tsx`)
- Added `tanggapan` field to `LaporanData` interface
- Added `respondLaporan` function to handle API calls
- Updated data transformation to include `tanggapan` from `admin_response`

### 4. DetailLaporan Page (`src/pages/DetailLaporan.tsx`)
- Updated button from "Tangani" to show properly in the UI
- Added "Tanggapan" section in the main view (shown if exists)
- Added ability to add/edit tanggapan in the "Tangani Laporan" view
- Added "Simpan & Selesaikan" button that saves response and marks laporan as "SELESAI"
- Added status indicator showing "Selesai" badge when laporan is resolved

## How it works:
1. Admin clicks "Tangani" button on a laporan
2. Admin writes a response/tanggapan in the text area
3. Admin clicks "Simpan & Selesaikan" to save and mark the laporan as resolved
4. The tanggapan is saved to the backend and status is set to "SELESAI"
5. The main view shows the "Selesai" badge and displays the tanggapan if it exists
