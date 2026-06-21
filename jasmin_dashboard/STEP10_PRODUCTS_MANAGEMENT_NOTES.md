# Step 10 — Products / Packages Management

This step builds Flutter-side product/package management for JASMIN_DASHBOARD.

## Added

- Product list screen connected to `GET /api/admin/products`
- Game dropdown/filter connected to `GET /api/admin/games`
- Search by package name, game, badge, supplier code, amount, and price
- Visibility filter: all / visible / hidden
- Create package screen connected to `POST /api/admin/products`
- Edit package screen connected to `GET/PATCH /api/admin/products/:id`
- Enable/disable package action
- Safe delete action connected to `DELETE /api/admin/products/:id`
- Pull-to-refresh and auto-refresh every 30 seconds
- Website update confirmation copy in UI

## Security behavior

Flutter only sends secure admin API requests with the Bearer token from Step 7.
It does not store database URLs, backend secrets, TOTP secrets, or admin passwords.

Product changes are still protected by backend role checks, backend validation, audit logs, and website revalidation from previous steps.

## Test

```bash
cd jasmin_dashboard
flutter pub get
flutter analyze
flutter run --dart-define=JASMIN_API_BASE_URL=http://10.0.2.2:3000
```

Test flow:

1. Login with email/password.
2. Verify Google Authenticator 2FA.
3. Open Products.
4. Search/filter packages.
5. Create a package.
6. Edit price/amount/game association.
7. Hide/show a package.
8. Delete safely.
9. Check the website game page updates shortly after changes.
