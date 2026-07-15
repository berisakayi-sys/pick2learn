# Pick2Learn 📚

**Scan it. Understand it. Learn it.**

A beginner-friendly, cross-platform homework helper built with **Flutter**. It runs on
**Android, iOS (including iOS 12.5.7), Web, Windows, macOS, and Linux** from a single codebase.

## ✨ Features

- 🏠 **Home** with large, colorful buttons for every tool
- 📷 **Scan Homework** (live camera), **Take a Photo**, and **Upload a Photo**
- 🔤 **OCR** that reads printed *and* handwritten text — via the cloud, so it works even on old devices and the web
- ✍️ **Type a Question** about any subject
- 🧮 **Math Calculator** with instant results and an "explain step by step" button
- ⏱️ **Study Timer** (Pomodoro-style focus/break)
- 🃏 **Flashcards** you can flip, favorite, and organize by subject
- 🕘 **History** with **search** and **bookmarks/favorites**
- 🧠 **Step-by-step explanations** (or "answer only" if you prefer) for **math, science, English, history, geography, languages** and more
- 💬 **Follow-up questions** on any answer
- 🌗 **Dark & light mode** (+ Material You dynamic color on Android 12+)
- 💾 **Offline local storage** of all your homework
- 📱 **Responsive** layouts for phones, tablets, and desktops
- 🧯 Graceful **error handling** everywhere

## 🧱 Project structure

```
lib/
├─ main.dart                 # App entry point (loads settings + database)
├─ app.dart                  # Root MaterialApp, themes, theme mode
├─ core/
│  ├─ theme/                 # Colors + Material 3 light/dark themes
│  ├─ constants/             # App-wide constant values
│  └─ utils/                 # Responsive helpers + friendly error type
├─ models/                   # HomeworkItem, ChatMessage, Subject, Flashcard
├─ services/                 # AI (OCR + explain), database, settings, images
├─ providers/                # Riverpod state (settings, homework, flashcards)
├─ screens/                  # One folder per screen (home, scan, answer, …)
└─ widgets/                  # Reusable UI pieces (cards, error/empty views…)
```

**Architecture:** clean separation into *models → services → providers → screens/widgets*,
with **Riverpod** for state management. Every file is commented to explain what it does.

---

## 🚀 Running the project in Visual Studio Code

### 1. Install the tools (one time)

1. Install **Flutter**: <https://docs.flutter.dev/get-started/install>
   > ⚠️ **iOS 12.5.7 note:** use the latest **stable Flutter 3.32.x** — the last
   > stable release that still supports iOS 12. Flutter **3.35 dropped iOS 12**
   > and raised the minimum to iOS 13. This project also needs Flutter **3.27+**
   > for the `Color.withValues()` API, so the valid stable range is **3.27–3.32**.
   > Download from the **Stable channel** section of
   > <https://docs.flutter.dev/install/archive> (do NOT use a `.pre` beta build).
   > Check your version with `flutter --version`.
2. Install **VS Code**: <https://code.visualstudio.com/>
3. In VS Code, open **Extensions** (Ctrl+Shift+X) and install:
   - **Flutter** (by Dart Code) — this also installs the Dart extension.
4. Confirm your setup is healthy:
   ```bash
   flutter doctor
   ```

### 2. Open the project

- **File → Open Folder…** and choose this `Pick2Learn` folder.

### 3. Generate the native platform folders (one time)

This repo contains the Dart source and `pubspec.yaml`. Generate the
`android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/` folders with:

```bash
flutter create .
```

> This command **keeps** all existing files in `lib/` and your `pubspec.yaml`;
> it only adds the missing native folders.

### 4. Get the packages

```bash
flutter pub get
```

### 5. Add your AI key

The OCR and step-by-step explanations use the **Anthropic Claude API**.

1. Get an API key from <https://console.anthropic.com/>.
2. Run the app (next step), open **Settings → AI connection**, paste the key, and tap **Save**.

> The key is stored locally on the device only. For a real production release
> you'd route these requests through your own backend so the key never ships in
> the app — see the note at the top of `lib/services/ai_service.dart`.

### 6. Run it 🎉

- Pick a device in the VS Code status bar (bottom-right): Chrome, Windows,
  an Android emulator, an iOS simulator, etc.
- Press **F5** (Run → Start Debugging), or in a terminal:
  ```bash
  flutter run -d chrome      # Web
  flutter run -d windows     # Windows desktop
  flutter run                # First available device (phone/emulator)
  ```

---

## 🍏 Making it work on iOS 12.5.7

After `flutter create .`, apply these three changes so the app builds and runs
on iOS 12.5.7:

**1. `ios/Podfile`** — set the platform line near the top:
```ruby
platform :ios, '12.0'
```

> Make sure you're on stable Flutter **3.27–3.32** (see the version note above);
> Flutter 3.35+ will not build for iOS 12.

**2. Deployment target** — in Xcode open `ios/Runner.xcworkspace`, select the
**Runner** target → **General** → set **Minimum Deployments → iOS 12.0**.
(Or set `IPHONEOS_DEPLOYMENT_TARGET = 12.0` in `ios/Runner.xcodeproj/project.pbxproj`.)

**3. Permissions** — add these keys inside `ios/Runner/Info.plist`
(`<dict>…</dict>`) so the camera and photo picker are allowed:
```xml
<key>NSCameraUsageDescription</key>
<string>Pick2Learn uses the camera to scan your homework.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Pick2Learn lets you upload a photo of your homework.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Not used for audio — required by the camera component.</string>
```

Then:
```bash
cd ios && pod install && cd ..
flutter run
```

> Because OCR runs in the **cloud** (not on-device ML), it works fine on iOS
> 12.5.7. On-device ML Kit is intentionally **not** used, since current versions
> require iOS 15+.

---

## 📲 Put it on your iPad WITHOUT owning a Mac

Apple normally requires a Mac to build iOS apps. This project is set up so you
can do it **without one**, by (1) building the `.ipa` on a cloud Mac with
**Codemagic**, then (2) installing it from your Windows PC with **Sideloadly**
using a **free Apple ID**.

> ⚠️ Reality check: with a *free* Apple ID the installed app **stops working
> after 7 days** and must be reinstalled (Apple's rule). A paid Apple Developer
> account ($99/yr) extends this to a year. Also, TestFlight is NOT an option for
> iOS 12 — the TestFlight app itself requires a newer iOS.

### Part 1 — Put the code on GitHub
1. Make a free account at <https://github.com> and create a **new empty repo**
   called `pick2learn` (no README — this project already has one).
2. In this project folder, connect and push (replace `YOU`):
   ```bash
   git remote add origin https://github.com/YOU/pick2learn.git
   git push -u origin main
   ```

### Part 2 — Build the .ipa in the cloud (Codemagic)
1. Sign up at <https://codemagic.io> with your GitHub account (free tier).
2. **Add application → pick2learn repo.** Codemagic detects `codemagic.yaml`.
3. Run the **"iOS unsigned IPA (for sideloading)"** workflow.
4. When it finishes (~10–15 min), download the **`Pick2Learn-unsigned.ipa`**
   artifact to your Windows PC.

### Part 3 — Install it on the iPad from Windows (Sideloadly)
1. Install **iTunes** (Apple's site) and **Sideloadly** from
   <https://sideloadly.io> on your Windows PC.
2. Plug the iPad into the PC with a cable; tap **Trust** on the iPad.
3. Open Sideloadly, drag in `Pick2Learn-unsigned.ipa`, enter your **Apple ID**,
   and click **Start**. (It signs the app with your Apple ID.)
4. On the iPad: **Settings → General → VPN & Device Management →** tap your
   Apple ID → **Trust**.
5. Open **Pick2Learn** from the home screen. 🎉
6. In the app, open **Settings** and paste your AI key so OCR + answers work.

> To avoid the 7-day reinstall hassle, install **AltStore** instead of
> Sideloadly — it can auto-refresh the app while your PC is on the same Wi-Fi.
> AltStore works on iOS 12.2+, so it supports your iPad.

---

## 🤖 Android notes

`flutter create .` sets sensible defaults. The `image_picker` and `camera`
plugins work out of the box on modern Android. If you target very old devices,
open `android/app/build.gradle` and confirm `minSdkVersion` is at least `21`.

## 🖥️ Desktop & Web notes

- **Web / Windows / Linux / macOS** all work; history uses a cross-platform
  SQLite backend selected automatically in `lib/services/database_service.dart`.
- The **live camera** ("Scan Homework") may be unavailable on some desktop
  setups — the app detects this and offers **Take a Photo / Upload** instead, so
  it never dead-ends.

## 🧰 Troubleshooting

| Problem | Fix |
| --- | --- |
| `No key set yet` / answers fail | Add your API key in **Settings**. |
| iOS build fails on old device | Confirm the three iOS 12 steps above and that you're on Flutter 3.24.x. |
| Web SQLite errors | Run `flutter pub get` again; the web SQLite worker downloads on first run. |
| Camera is black on desktop | Expected on some desktops — use **Take a Photo / Upload**. |

---

Made with ❤️ using Flutter + Material 3.
