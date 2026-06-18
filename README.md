# Midsommer Madness 🇸🇪

Midsommer Madness is a Swedish-themed action retro arcade game inspired by *Redneck Rampage* and the Swedish Midsummer holiday. 

Help Sven race against the solar timer to reach the Maypole (*midsommarstång*) before sundown! If you fail, the solstice is lost, you trigger a meltdown, and you are sacrificed to the Wicker Man.

---

## 📸 Screen Gallery

| Title Screen | Game Over Screen | Victory Screen |
| :---: | :---: | :---: |
| ![Title Screen](assets/midsommer_madness_title.png) | ![Meltdown Screen](assets/midsommer_meltdown.png) | ![Victory Screen](assets/midsommer_victory.png) |

---

## 🎮 Level Sequence

The game features ten distinct thematic levels:
1. **IKEA Warehouse:** Battle crowded, flatpack-carrying shoppers who throw box projectiles at you.
2. **Systembolaget:** The state-owned liquor shop crowded with drunk Swedes stumbling and lobbing green beer bottles.
3. **Lördagsgodis:** Sugar rush Saturday! Dodge hyperactive, strung-out Swedish kids throwing sweet candy projectiles.
4. **The Swedish Pub:** Sing along with Frank Zappa fans singing "Bobby Brown" (shouting and firing glowing letters `B`, `O`, `B`, `B`, `Y`).
5. **Volvo Highway:** A survival lane-crossing level where boxy blue Volvo station wagons zoom across lanes at high speeds.
6. **Dalarna Forest:** Deep green woods where giant red wooden Dalarna Horses charge at Sven in sudden dash-bursts.
7. **Allemansrätten:** Swedish right to roam! Harvest wild cloudberries while dodging aggressive elk charging and stomping.
8. **Kvinnafängelset:** Escape the Swedish women's prison! Dodging strict guards throwing heavy metal handcuffs.
9. **Avicii Rave:** A dark neon rave under strobe lights. Dance through ravers wearing shades who throw glowing glowsticks.
10. **ABBA Disco:** The final level under glowing purple lights. Chrome ABBA Bots fire multi-directional pink disco laser spreads. Reach the Maypole in the center to save Midsummer!

---

## 🛠️ Combat & Mechanics

- **Fixed Timestep Loop:** Game logic updates at a solid 60Hz timestep, while rendering runs at the browser's maximum frame rate (interpolated) to ensure smooth gameplay.
- **Hockey Stick (Melee):** Left-click swings the stick in front of Sven towards the cursor, damaging and knocking back enemies. Alternatively, press **H** as a keyboard shortcut.
- **Surströmming Bomb (Ranged):** Right-click or Space throws a canned fermented herring that explodes, creating a lingering toxic green gas cloud that damages all enemies inside.
- **Swedish Power-Ups:**
  - **Köttbullar (Meatballs):** Restores 25 energy.
  - **Knäckebröd (Crispbread):** Grants a 4-second speed boost (+50% speed) and a yellow dotted forcefield shield (blocks 80% of damage).
- **Procedural Synthesizer (Web Audio API):** All game music and SFX are procedurally synthesized in real-time, adjusting BPM, scales, and motifs depending on the level (e.g. happy chiptunes, acoustic folk, heavy metal, EDM, and disco).
- **Screen Shake:** Dynamic impact feedback on hits and stomps.

---

## 🚀 How to Play Locally

1. Start the local server:
   ```bash
   make dev
   ```
   *Alternatively, run `npm run dev`.*
2. Open your browser and navigate to the port displayed in the console output.

---

## ⌨️ Controls

- **W, A, S, D** or **Arrow Keys** — Move Sven
- **Mouse Movement** — Aim
- **Left Click** or **H** — Swing Hockey Stick (Melee)
- **Right Click** or **Space** — Throw Surströmming Bomb (Ranged)

---

## 📱 Flutter App Wrapping & Firebase Integration

This project is wrapped in a full-screen, landscape-locked Flutter `WebViewWidget` that runs the web-based game. It features:
* **Firebase Cloud Leaderboard**: Real-time high-score sync with Cloud Firestore.
* **Firebase Analytics**: Tracks game events (e.g., state transitions, victory, game over, and scores) directly from the JavaScript layer.
* **Firebase Crashlytics**: Collects fatal and non-fatal errors from the Flutter native app, as well as unhandled JavaScript exceptions from the WebView game loop.
* **Firebase Performance Monitoring**: Employs custom traces (`get_leaderboard_scores` and `save_leaderboard_score`) to track the latency of leaderboard fetch and submission operations.
* **Offline Caching Fallback**: Seamless fallback to local `SharedPreferences` cache (on mobile) or `localStorage` (on web) if offline or if Firebase credentials are unconfigured.
* **Interactive High-Score Submission**: A custom Name Input Form appears automatically upon Victory or Game Over if the player qualifies for the Top 5 leaderboard.
* **Mobile Touch Controls**: A virtual joystick zone and custom action buttons on mobile touch layouts.
* **Aspect-Ratio Scaling**: Automatic resizing of the HTML5 canvas to fit mobile screen resolutions.
* **Sticky Full-Screen Immersive Mode**: Hides system status bars and navigation menus using Flutter's native window/system chrome configurations.
* **Bypassed Audio Gesture Constraints**: Autoplay is enabled on the WebView so audio triggers without needing explicit user touch gestures.

### 🔌 JavaScript-to-Native Bridge (LeaderboardChannel)

Communication between the WebView (`assets/game.js`) and Flutter (`lib/main.dart`) is facilitated via a JavaScript Channel named `LeaderboardChannel`. Message payloads are sent as JSON strings with the following formats:

1. **Fetch Leaderboard Scores**
   ```json
   { "type": "getScores" }
   ```
   *Native action: Fetches current high scores, saves to local cache, and calls `window.onScoresLoaded(scoresJson)` on completion.*

2. **Save Player Score**
   ```json
   {
     "type": "saveScore",
     "name": "Sven",
     "score": 15000
   }
   ```
   *Native action: Commits the player record to Firestore and records a score post to Analytics.*

3. **Log Analytics Event**
   ```json
   {
     "type": "logEvent",
     "name": "level_start",
     "parameters": {
       "level_id": "ikea_warehouse",
       "level_title": "1. IKEA Warehouse"
     }
   }
   ```
   *Native action: Routes custom gameplay metrics directly to Firebase Analytics.*

4. **Record JavaScript Exception**
   ```json
   {
     "type": "recordError",
     "message": "TypeError: Cannot read properties of undefined (at game.js:123:45)",
     "stack": "TypeError: Cannot read properties of undefined\n  at Game.update (game.js:123:45)"
   }
   ```
   *Native action: Submits WebView exceptions to Firebase Crashlytics as non-fatal runtime issues.*

### Flutter Project Structure
- [main.dart](file:///home/xbill/midsommer-firebase/lib/main.dart): Sets up full-screen immersive view, locks orientation to landscape, initializes Firebase (Analytics, Crashlytics, Performance), registers the `LeaderboardChannel` JavaScript bridge, and handles offline caching.
- [pubspec.yaml](file:///home/xbill/midsommer-firebase/pubspec.yaml): Manages Dart packages (`webview_flutter`, `firebase_core`, `cloud_firestore`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `shared_preferences`) and registers game assets.
- [index.html](file:///home/xbill/midsommer-firebase/assets/index.html): Mobile-first touch UI canvas, high-score input forms, and entry point.

### 🛠️ Building and Deploying via CLI (Makefile)

We provide a [Makefile](file:///home/xbill/midsommer-firebase/Makefile) to simplify local development, compilation, and logs monitoring:

1. **Local Web Development**:
   ```bash
   make dev
   ```
   *Serves files directly from the assets directory to play in the browser.*

2. **Compile Android Debug APK**:
   ```bash
   make build-apk
   ```
   *Runs `flutter build apk --debug` to produce a debug APK.*

3. **Install on Connected Device/Emulator**:
   ```bash
   make install-apk
   ```
   *Installs the compiled build using `flutter install`.*

4. **Monitor Device Logs**:
   ```bash
   make logcat
   ```
   *Views real-time logs using `flutter logs`.*

5. **Deploy Web App to Firebase Hosting**:
    ```bash
    make deploy
    ```
    *Manually deploys the static assets inside the `assets/` directory to Firebase Hosting.*

---

## 🌐 GitHub Repository & CI/CD Deployment

This project is hosted on GitHub at [xbill9/midsommer-firebase](https://github.com/xbill9/midsommer-firebase).

Automated deployment is configured via GitHub Actions:
* **Pull Request Preview**: Every PR targeting the `master` branch triggers `.github/workflows/firebase-hosting-pull-request.yml`, which deploys a temporary preview channel of the game for testing.
* **Production Deploy**: Pushing or merging to the `master` branch triggers `.github/workflows/firebase-hosting-merge.yml`, which automatically deploys the latest version to the live Firebase Hosting site.


 6. **Clean Workspace Caches**:
   ```bash
   make clean
   ```
   *Cleans the Flutter project build directories and temporary caches.*

 7. **Fetch Cloud Firebase Logs**:
    ```bash
    make firebase-logs
    ```
    *Fetches the latest 20 cloud logs and audit logs directly from your Google Cloud/Firebase project using the `gcloud` CLI.*
