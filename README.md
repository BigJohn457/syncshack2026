# Hey!

Hey! is a Flutter meetup app for discovering nearby requests, joining group
meetups, chatting, revealing profiles, and finding compatible friends through
optional AI matchmaking.

The Flutter application is in `frontend/app_runner`. By default, it connects to
the deployed API at `https://heybe.shahfitri.my`, so running the backend locally
is optional.

## Android: install the APK

The Android release APK is included in this repository:

### [Download Hey! for Android](downloads/Hey.apk)

File: `downloads/Hey.apk` (approximately 53.5 MB)


1. Open this README on the Android phone.
2. Select **Download Hey! for Android** above.
3. Open the downloaded file.
4. If Android asks, allow installation from that browser or file manager.
5. Select **Install**, then open **Hey!**.

If the APK link is unavailable in a copy of this project, run the app with
Flutter using the instructions below.

## Run with Flutter

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Git
- Android Studio for Android Emulator and Android SDK support
- Xcode for iPhone Simulator support on macOS

Confirm the toolchain is ready:

```bash
flutter doctor
```

Clone the project and install the Flutter packages:

```bash
git clone https://github.com/BigJohn457/syncshack2026.git
cd syncshack2026/frontend/app_runner
flutter pub get
```

List the available phones and simulators:

```bash
flutter devices
```

Run Hey! on a connected device or an already-open simulator:

```bash
flutter run
```

When more than one device is available, select one explicitly:

```bash
flutter run -d <device-id>
```

The app needs location permission to display nearby requests. Allow location
access when the device asks.

## macOS: run on iPhone Simulator

Install Flutter and Xcode first, then accept the Xcode licence and complete its
initial setup:

```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

Open an iPhone Simulator:

```bash
open -a Simulator
```

From `frontend/app_runner`, install dependencies and run the app:

```bash
flutter pub get
flutter run
```

If CocoaPods dependencies need refreshing:

```bash
cd ios
pod install
cd ..
flutter run
```

## Run on Android with Flutter

Start an Android Emulator from Android Studio's Device Manager, or connect an
Android phone with USB debugging enabled. Then run:

```bash
cd frontend/app_runner
flutter pub get
flutter run
```

To build an installable APK yourself:

```bash
flutter build apk --release
```

The generated file will be located at:

```text
frontend/app_runner/build/app/outputs/flutter-apk/app-release.apk
```

Install it on a connected Android device with:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Optional: run the backend locally

The app already uses the deployed backend. Use this section only for backend
development.

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Fill in the database, storage, secret key, and DeepSeek settings in
`backend/.env`. Never commit that file. Then start Flask:

```bash
flask --app run run --debug
```

With the provided `.env.example`, the local API runs at
`http://127.0.0.1:8000`. To use it from Flutter, update `baseUrl` in
`frontend/app_runner/lib/api_config.dart`:

- iPhone Simulator: `http://127.0.0.1:8000`
- Android Emulator: `http://10.0.2.2:8000`
- Physical phone: use the computer's LAN IP, such as
  `http://192.168.1.10:8000`

The computer and physical phone must be on the same network, and the backend
must listen on `0.0.0.0` for another device to reach it.

## Tests

Flutter:

```bash
cd frontend/app_runner
flutter test
```

Backend:

```bash
cd backend
source venv/bin/activate
pytest
```
