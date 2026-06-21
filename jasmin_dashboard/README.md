# JASMIN_DASHBOARD

Flutter admin dashboard client for the JASMINTOPUP backend.

## Current step

Step 8 is complete: Dashboard Home is now wired to the Step 4 backend dashboard endpoint.

## What is included

- Splash/session check using `GET /api/admin/auth/me`
- Email/password login using `POST /api/admin/auth/login`
- Google Authenticator verification using `POST /api/admin/auth/2fa`
- Bearer token storage using Flutter Secure Storage
- Automatic `Authorization: Bearer <token>` header on admin requests
- 401/session-expired handling that clears local secure storage
- Logout using `POST /api/admin/auth/logout`
- Login validation, password visibility toggle, 2FA countdown, and safe error states
- Mobile-first pink/purple admin UI

## Generate platform folders

This environment did not have the Flutter CLI, so `android/` and `ios/` platform folders are not generated here.
On your computer, run:

```bash
cd jasmin_dashboard
flutter create --platforms=android,ios --project-name jasmin_dashboard .
flutter pub get
```

If Flutter overwrites `lib/main.dart`, `lib/app.dart`, or `pubspec.yaml`, restore them from this zip.

## Run locally

Android emulator talking to local Next.js backend:

```bash
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

Physical phone on same Wi-Fi:

```bash
flutter run --dart-define=JASMIN_API_BASE_URL=http://YOUR_PC_LAN_IP:3000
```

Production:

```bash
flutter run --dart-define=JASMIN_API_BASE_URL=https://www.jasmintopup.site
```


## Dashboard Home test flow

After login + Google Authenticator 2FA, the dashboard calls:

```txt
GET /api/admin/dashboard
```

Dashboard Home now includes:

- live stats cards
- today revenue
- order status summary
- recent orders
- system status
- unread notification badge
- refresh button
- pull-to-refresh
- auto-refresh every 20 seconds

Step 9 will build the full Orders management screens.

## Auth test flow

1. Run JASMINTOPUP backend.
2. Make sure admin 2FA is already configured from the website admin.
3. Open the Flutter app.
4. Login with admin email/password.
5. Enter the 6-digit Google Authenticator code.
6. Dashboard should open only after 2FA succeeds.
7. Tap account menu → Logout.
8. Reopen app; it should require login again.

## Security notes

- Do not store admin password in Flutter.
- Do not store database URL or backend secrets in Flutter.
- Do not store the Google Authenticator TOTP secret in Flutter.
- Store only the short-lived admin session token in secure storage.
- Backend must verify the Bearer token and admin role on every admin endpoint.
- A 401 response clears the local session and sends the admin back to login.


## Step 9 — Orders Management

The Orders screen now connects to the backend admin API. It supports:

- Live orders list from `GET /api/admin/orders`
- Search by order number, UID, customer, email, phone, or payment reference
- Status filters and pagination
- Pull-to-refresh, refresh button, and 20-second auto-refresh
- Order detail page at `/orders/:orderNumber`
- Status updates, delivery notes, failure reasons, and audit-only admin notes
- Copy order number shortcut

Status updates are protected by backend Bearer-token auth, role permissions, validation, audit logs, and website cache revalidation.


## Step 10 — Products / Packages Management

Products are now connected to the secure backend admin APIs. The app supports:

- Product/package list from `GET /api/admin/products`
- Game association from `GET /api/admin/games`
- Search and filters
- Create package
- Edit package
- Enable/disable package visibility
- Safe delete package
- Pull-to-refresh and auto-refresh

Run with the same API base URL used in earlier steps:

```bash
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

After updating a package, the backend audit log and website cache revalidation should make the JASMINTOPUP website reflect the change shortly.

## Step 11 — Games Management

Games Management is now connected to the secure backend admin API.

Features:

- List/search/filter games
- Create/edit games
- Edit slug, name, publisher/category label, description, image, banner, currency, UID label, server JSON, featured status, visibility, and SEO fields
- Enable/disable games from the list
- Safe delete games
- Reorder games up/down
- Pull-to-refresh and 30-second auto-refresh

Routes:

- `/games`
- `/games/new`
- `/games/:gameId`

Backend endpoints used:

- `GET /api/admin/games`
- `POST /api/admin/games`
- `GET /api/admin/games/:id`
- `PATCH /api/admin/games/:id`
- `DELETE /api/admin/games/:id`
- `POST /api/admin/games/reorder`


## Step 12 — Banners / Settings / FAQ

Step 12 adds full Flutter screens for:

- Homepage banners: list, search, create, edit, hide/show, delete
- Website settings: site name, exchange rate, maintenance mode, announcement, support links, logo/branding, Telegram notification fields
- FAQ content: list, search, category filter, create, edit, hide/show, delete

These screens use the secure admin API and the Bearer token created after Google Authenticator 2FA login.

### Useful routes

- `/banners`
- `/banners/new`
- `/settings`
- `/faqs`
- `/faqs/new`

### Test Step 12

```bash
cd jasmin_dashboard
flutter pub get
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

After login, test banner edits on the homepage, settings edits on global layout/maintenance/announcement, and FAQ edits on the FAQ page.
## Step 13: Promo Codes / Customers / Audit Logs / Notifications

Step 13 adds full Flutter screens for promo codes, customers, audit logs, and notifications. These screens use the secure Bearer token admin APIs created in the backend steps.

New routes:

- `/promo-codes`
- `/promo-codes/new`
- `/promo-codes/:promoId`
- `/customers`
- `/customers/:customerKey`
- `/audit-logs`
- `/notifications`

Test after login + Google Authenticator 2FA:

1. Open Promo Codes and create/edit/disable a code.
2. Open Customers and view order history.
3. Ban/unban a customer from customer detail.
4. Open Audit Logs and filter by action/admin/target.
5. Open Notifications and mark read/unread or mark all read.


## Step 14 — Auto Update Polish

Step 14 adds a global auto-update layer for the whole Flutter admin app.

What changed:

- Central refresh intervals in `lib/core/constants/refresh_intervals.dart`
- Global `AppSyncHost` that starts/stops sync after admin authentication
- Website public version polling using `GET /api/public/version`
- Global unread notification badge in the app bar
- Sync status icon in the app bar with manual refresh
- App resume refresh: when the app returns from background, visible admin data reloads
- Audit logs now auto-refresh every 45 seconds
- Existing module refresh timers now use shared interval constants

Useful behavior:

- Dashboard/orders/notifications keep fast polling.
- Products/games/banners/FAQ/customers/promo codes use stable 30-second polling.
- Website version is checked every 15 seconds so admins can confirm JASMINTOPUP refreshed after changes.
- Notification unread count is visible from every admin screen.

Test after login + Google Authenticator 2FA:

1. Open any admin screen and check the cloud sync icon in the app bar.
2. Tap the cloud sync icon to force a website version check.
3. Edit a banner/product/game/FAQ/settings item, then keep the public website open.
4. Wait around 10–20 seconds and confirm the website updates.
5. Send/create a new order notification and confirm the unread badge updates from any screen.
6. Put the app in background, reopen it, and confirm the visible screen refreshes.
