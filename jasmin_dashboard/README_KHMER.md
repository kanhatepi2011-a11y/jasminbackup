# JASMIN Dashboard Logo Fix v2

Pack នេះមិនមែនមានតែ PNG ទេ។ វាមាន **launcher icon files ពិតៗ** សម្រាប់ Android និង iOS។

## របៀបប្រើលើ Windows

1. Extract zip នេះ។
2. Copy folder/file ទាំងនេះចូល root folder របស់ JASMIN Dashboard Flutter app:
   - `assets/`
   - `android/`
   - `ios/`
   - `lib/widgets/jasmin_app_logo.dart`
   - `pubspec_logo_config.yaml` គ្រាន់តែយកទៅ merge មិនមែន copy ជំនួស pubspec.yaml ទាំងមូលទេ។

## វិធីងាយជាងនេះ

Copy folder `scripts/` ចូល root project របស់ Dashboard app ហើយ run:

```powershell
python scripts/apply_jasmin_dashboard_logo.py
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter pub get
flutter run
```

## សំខាន់

បើ app នៅតែបង្ហាញ logo ចាស់៖

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

បន្ទាប់មក uninstall app ចាស់ពី phone/emulator ហើយ install APK ថ្មីវិញ។ Android launcher ខ្លះ cache icon ចាស់។

## Code បង្ហាញ logo នៅ Login

```dart
import 'package:your_app/widgets/jasmin_app_logo.dart';

const JasminAppLogo(size: 96),
```

## Code បង្ហាញ logo នៅ AppBar

```dart
AppBar(
  title: Row(
    children: const [
      JasminAppLogo(size: 32),
      SizedBox(width: 10),
      Text('JASMIN Dashboard'),
    ],
  ),
)
```
