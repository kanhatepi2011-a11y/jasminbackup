# Step 13 — Promo Codes, Customers, Audit Logs, Notifications

This step adds Flutter admin UI and API integration for:

- Promo codes
- Customers
- Customer detail and ban/unban
- Audit logs
- Notifications

## Backend endpoints used

- `GET /api/admin/promo-codes`
- `POST /api/admin/promo-codes`
- `GET /api/admin/promo-codes/:id`
- `PATCH /api/admin/promo-codes/:id`
- `DELETE /api/admin/promo-codes/:id`
- `GET /api/admin/customers`
- `GET /api/admin/customers/:key`
- `PATCH /api/admin/customers/:key`
- `GET /api/admin/audit-logs`
- `GET /api/admin/notifications`
- `PATCH /api/admin/notifications`
- `PATCH /api/admin/notifications/:id`

## Security

- All requests use the Step 7 Bearer token interceptor.
- Customer ban/unban uses existing `BlockedIdentity` backend logic.
- Audit logs are read-only in Flutter.
- Promo delete uses backend safe delete behavior.
- Notifications can only be marked read/unread; no destructive action was added.

## Testing

Run the backend, then run Flutter:

```bash
cd jasmin_dashboard
flutter pub get
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

Then test:

1. Create/edit/disable a promo code.
2. Search a customer and open detail.
3. Ban/unban a customer.
4. Filter audit logs.
5. Mark a notification read/unread and mark all read.
