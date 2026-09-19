$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "Setting up USB port forwarding for Firebase Emulators..." -ForegroundColor Cyan
& $adbPath reverse tcp:5001 tcp:5001
& $adbPath reverse tcp:8080 tcp:8080
& $adbPath reverse tcp:9099 tcp:9099

if ($LASTEXITCODE -eq 0) {
    Write-Host "Port forwarding successful!" -ForegroundColor Green
} else {
    Write-Host "Warning: ADB port forwarding failed. Make sure your device is connected via USB." -ForegroundColor Yellow
}

Write-Host "Launching Flutter with Emulator configuration..." -ForegroundColor Cyan
flutter run -d 29091JEGR00954 --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
