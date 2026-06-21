# Step 9 — Orders Management

This step adds the Flutter orders management feature for `JASMIN_DASHBOARD`.

## Added

- Orders list connected to `GET /api/admin/orders`
- Search by order number, UID, customer, phone, email, or payment reference
- Status filters: All, Pending, Paid, Processing, Completed, Failed, Cancelled
- Pagination controls
- Pull-to-refresh and refresh button
- Auto-refresh every 20 seconds
- Order detail route: `/orders/:orderNumber`
- Order detail connected to `GET /api/admin/orders/[orderNumber]`
- Status/note update connected to `PATCH /api/admin/orders/[orderNumber]`
- Copy order number button
- Delivery note and failure reason management
- Audit-only admin note field
- Payment-sensitive warning in the update dialog

## Security note

This screen does not bypass payment protections. Status changes are admin actions and should only be used after the admin verifies real order/payment state. The backend still performs token, role, input validation, audit logging, and cache revalidation.

## Test

```bash
cd jasmin_dashboard
flutter pub get
flutter analyze
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

Then login with email/password + Google Authenticator 2FA and open Orders.
