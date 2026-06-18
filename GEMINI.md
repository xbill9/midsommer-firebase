use this for skills:

https://github.com/sickn33/antigravity-awesome-skills/tree/main

https://github.com/sickn33/antigravity-awesome-skills/blob/main/skills/game-development/SKILL.md

---

# 🇸🇪 Midsommer Madness Developer Guidelines for Gemini (Flutter Version)

Welcome! This file contains developer context, architecture notes, and guidelines for working on this project.

## 🛠️ Build and Automation Commands

Use the provided `Makefile` to run, build, and debug this application:

* **Local Web Development**: `make dev` or `make run` (serves files directly from the `assets/` directory)
* **Compile Android App**: `make build-apk` (runs `flutter build apk --debug`)
* **Deploy to Device/Emulator**: `make install-apk` (runs `flutter install`)
* **Clean Build Directories**: `make clean` (runs `flutter clean`)
* **Monitor Logs**: `make logcat` (runs `flutter logs`)
* **Deploy Web App to Firebase**: `make deploy` (uses `npx -y firebase-tools` to publish the web game to Firebase Hosting)

## 📂 Project Architecture

* **Web Assets**: The core game is implemented in vanilla HTML, JS, and CSS located inside the `assets/` directory:
  * [index.html](file:///home/xbill/midsommer-firebase/assets/index.html): Entry point, mobile-first touch UI canvas, and custom high-score name entry forms.
  * [game.js](file:///home/xbill/midsommer-firebase/assets/game.js): Gameplay loop (60Hz fixed timestep), rendering, physics, procedural Web Audio synthesizer, touchscreen joystick input logic, and Firebase/offline leaderboard sync.
  * [index.css](file:///home/xbill/midsommer-firebase/assets/index.css): Styling, layout, animations, and retro colors.
* **Flutter Wrapper**: Located in the main project, wrapping the web files inside a full-screen, landscape-locked `WebViewWidget`:
  * [main.dart](file:///home/xbill/midsommer-firebase/lib/main.dart): Sets up fullscreen sticky immersive mode, configures the `WebViewController` with unrestricted JavaScript, initializes Firebase, handles Firestore leaderboard reading/writing via the `LeaderboardChannel` JavaScript channel, and falls back to local `SharedPreferences` if unconfigured or offline.
  * [pubspec.yaml](file:///home/xbill/midsommer-firebase/pubspec.yaml): Registers dependencies like `webview_flutter`, `firebase_core`, `cloud_firestore`, `shared_preferences`, and configures the `assets/` directory.
* **Firebase Configuration**:
  * [firebase.json](file:///home/xbill/midsommer-firebase/firebase.json) & [.firebaserc](file:///home/xbill/midsommer-firebase/.firebaserc): Configuration rules and target project definition for Firebase Web Hosting.
  * [google-services.json](file:///home/xbill/midsommer-firebase/android/app/google-services.json): Placeholders required to compile Google Services on Android, replaceable with production credentials.

## ⚠️ Key Instructions for Gemini / Antigravity

1. **Asset Modifications**: If you modify `game.js`, `index.html`, or `index.css` under the `assets/` directory, the changes will be automatically picked up on the next hot restart or Flutter build.
2. **Web Audio Compatibility**: The Android WebView requires user interaction to initialize the Web Audio API context. Ensure `AudioContext` resumes on first touch/click.
3. **Responsive Canvas**: Keep the target aspect ratio in mind when tweaking layouts. Touch controls should dynamically scale.
4. **Procedural Audio Synthesis**: Do not use raw audio file formats. Audio effects and background tracks are procedurally generated in `assets/game.js` via the Web Audio API's `SoundEffectsManager`. Scales and tempos are programmatically shifted to suit the atmosphere of the active level.
5. **Level-Specific Classes**: Each level features specific enemy types subclassed from the generic `Enemy` parent class (e.g., `Shopper`, `Drunkard`, `CandyKid`, `ZappaFan`, `VolvoCar`, `DalarnaHorse`, `Elk`, `Guard`, `Raver`, `ABBAbot`). Ensure any game balance tweaks or new mechanics honor these subclass extensions.
6. **Firebase Leaderboard Channel**: High scores are synchronized via `LeaderboardChannel` using standard JSON communication. If Firebase fails to initialize or is offline, the systems fallback to `SharedPreferences` cache (on mobile) or `localStorage` (on web) cleanly without breaking gameplay.

