# Step 8 — Dashboard Home

This step connects the Flutter dashboard home screen to the JASMINTOPUP backend endpoint:

```txt
GET /api/admin/dashboard
```

## Included

- Dashboard API client and repository
- Dashboard models for stats, recent orders, products, games, and system status
- Riverpod dashboard controller
- Initial loading state
- Pull-to-refresh
- Manual refresh button
- Auto-refresh every 20 seconds
- Notification badge from unread notifications count
- Responsive dashboard stats grid
- Recent orders card
- Order status summary card
- System status card
- Quick action chips
- Safe error card with retry

## Not included yet

Step 9 will build full orders management. Recent orders in Step 8 only link to the Orders screen placeholder.

## Test

```bash
cd jasmin_dashboard
flutter pub get
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

Login with admin email/password + Google Authenticator 2FA, then open the dashboard.

Expected:

- Dashboard loads live stats from `/api/admin/dashboard`
- Refresh button reloads data
- Pull-to-refresh reloads data
- Data auto-refreshes every 20 seconds
- Recent orders are listed if backend has orders
- 401 response clears session through the auth interceptor
