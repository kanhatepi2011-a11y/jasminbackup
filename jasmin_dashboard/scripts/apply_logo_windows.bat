@echo off
echo Applying JASMIN Dashboard logo...
python scripts\apply_jasmin_dashboard_logo.py
echo.
echo Now run:
echo flutter pub get
echo dart run flutter_launcher_icons
echo flutter clean
echo flutter pub get
echo flutter run
pause
