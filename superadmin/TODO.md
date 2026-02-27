# TODO - Change Status Name to "blocked"

## Plan:
1. [ ] `backend/src/routes/customer.routes.ts`
   - [x] Change block endpoint to store `'blocked'` instead of `'suspended'`
   - [x] Change unblock endpoint to handle `'blocked'` status

2. [ ] `src/contexts/CustomerContext.tsx`
   - [x] Update status map: `'blocked'` → display as `'blocked'`
   - [x] Remove or update `'suspended'` mapping

3. [ ] `src/pages/BlokirCustomer.tsx`
   - [x] Change filter from `"DIBLOCK"` to `"blocked"`
   - [x] Change badge display from "BLOCK" to "blocked"
