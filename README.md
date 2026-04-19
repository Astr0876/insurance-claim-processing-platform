# LockIn (Lumina) — Proactive Student Sidekick

> A Flutter app that helps college students manage attendance, track tasks, study with AI assistance, and stay on top of their academic life.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.11.5+)
- Dart SDK (3.x)
- Xcode 16+ (for iOS)
- Android SDK + Java 17 (for Android)

### Setup

```bash
# 1. Clone and install
git clone <repo-url>
cd LockIn
flutter pub get

# 2. Create .env file
cp .env.example .env
# Add your keys (see Environment Variables below)

# 3. Run
flutter run
```

### Environment Variables

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_AUTH_REDIRECT_URL=lumina://auth/callback
GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
GEMINI_API_KEY=your-gemini-api-key
```

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | ✅ | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous API key |
| `SUPABASE_AUTH_REDIRECT_URL` | ⚠️ | Redirect URL used in Supabase auth emails. Use your app deep link (recommended) or your production web callback URL. |
| `GOOGLE_WEB_CLIENT_ID` | ⚠️ | Google OAuth Web Client ID used by Google Sign-In (`*.apps.googleusercontent.com`). |
| `GEMINI_API_KEY` | ⚠️ | Google Gemini API key (for AI features). Get one at [aistudio.google.com](https://aistudio.google.com) |

---

## 📱 Platform Support

| Feature | iOS (Real Device) | iOS (Simulator) | Android | Windows |
|---------|-------------------|-----------------|---------|---------|
| UI / Navigation | ✅ | ✅ | ✅ | ❌ |
| Supabase Auth | ✅ | ✅ | ✅ | ❌ |
| Google Sign-In | ✅ | ✅ | ✅ | ❌ |
| Attendance Tracking | ✅ | ✅ | ✅ | ❌ |
| Kanban Board | ✅ | ✅ | ✅ | ❌ |
| Timetable / Calendar | ✅ | ✅ | ✅ | ❌ |
| Focus Timer | ✅ | ✅ | ✅ | ❌ |
| Expense Tracker | ✅ | ✅ | ✅ | ❌ |
| OCR (MLKit) | ✅ | ⚠️ | ✅ | ❌ |
| AI Chat (Gemini) | ✅ | ✅ | ✅ | ❌ |
| Home Widgets | ❌ | ❌ | ✅ | ❌ |
| RunAnywhere (On-Device AI) | ✅ | ❌ | ⚠️ | ❌ |

**Notes:**
- **iOS Simulator**: Use iPhone 16 Pro Max (iOS 18.6), NOT iPhone 17 (iOS 26). iOS 26 simulators require arm64 which conflicts with MLKit.
- **Android**: RunAnywhere native binaries aren't published by the upstream plugin, so on-device AI won't function. Gemini AI works as the replacement.
- **Windows**: Not supported by the RunAnywhere plugin.

---

## 🤖 AI Features

### Gemini AI (Primary — Works Everywhere)
The app uses **Google Gemini 2.0 Flash** for AI features:
- Chat assistant ("Lumina")
- Study note summarization
- Quiz generation from notes
- Attendance advice
- Knowledge graph analysis

**Setup**: Add `GEMINI_API_KEY` to your `.env` file. Get a free key at [aistudio.google.com](https://aistudio.google.com).

### RunAnywhere SDK (Legacy — Limited)
The original on-device AI SDK (`runanywhere`) has known issues:
- ❌ Android: Native `.so` binaries are **not published** in GitHub releases
- ❌ iOS Simulator: Native C++ library crashes with SIGSEGV (missing symbols)
- ✅ iOS Real Device: Works when native libs are available

The app gracefully falls back to Gemini when RunAnywhere is unavailable.

---

## 📲 Android Home Screen Widgets

The app includes **3 home screen widgets**:

### 1. Dashboard Widget
Shows: next class, attendance %, risk level, upcoming deadlines.

### 2. Attendance Widget ⭐
- Shows next class name and time
- Current attendance percentage (big number)
- **▲ Prediction** if you attend (green)
- **▼ Prediction** if you skip (red)
- Safe bunks remaining
- **✓ PRESENT / ✗ ABSENT** action buttons right in the widget

### 3. Kanban Board Widget ⭐
- Horizontally scrollable across TODO → DOING → DONE columns
- Shows task counts per column
- Lists up to 3 tasks per column
- Tap to open the app

**To add widgets:**
1. Long-press on Android home screen
2. Select "Widgets"
3. Find "Lumina" → choose Dashboard, Attendance, or Kanban
4. Drag to home screen

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point, SDK init
├── app/
│   └── app_shell.dart           # Main navigation shell
├── core/
│   ├── providers/app_state.dart  # Central state management
│   ├── services/
│   │   ├── gemini_service.dart   # Gemini AI integration
│   │   ├── ai_model_service.dart # RunAnywhere wrapper (legacy)
│   │   ├── assistant_service.dart# Chat assistant
│   │   ├── home_widget_service.dart # Widget data bridge
│   │   ├── attendance_service.dart
│   │   ├── kanban_service.dart
│   │   ├── timetable_service.dart
│   │   └── ...
│   ├── theme/                   # Neubrutalism design tokens
│   └── widgets/                 # Shared UI components
├── features/
│   ├── attendance/              # Attendance tracking
│   ├── kanban/                  # Kanban task board
│   ├── assistant/               # AI chat assistant
│   ├── timetable/               # Class schedule
│   ├── focus/                   # Focus timer
│   ├── expenses/                # Expense tracker
│   ├── study_hub/               # Study materials
│   └── ...
android/
├── app/src/main/
│   ├── kotlin/.../
│   │   ├── HomeWidgetProvider.kt        # Dashboard widget
│   │   ├── AttendanceWidgetProvider.kt  # Attendance widget
│   │   └── KanbanWidgetProvider.kt      # Kanban widget
│   ├── res/layout/
│   │   ├── widget_layout.xml            # Dashboard layout
│   │   ├── attendance_widget_layout.xml # Attendance layout
│   │   └── kanban_widget_layout.xml     # Kanban layout
│   └── AndroidManifest.xml
```

---

## 🔧 Android Build Fix

The `runanywhere` Flutter plugin has broken download URLs for Android native libraries. If you get a `downloadNativeLibs` error:

**macOS/Linux:**
```bash
bash scripts/setup_android_native_libs.sh
```

**Windows:**
```batch
scripts\setup_android_native_libs.bat
```

This patches the pub cache to gracefully skip the broken downloads. Re-run after `flutter clean` or `flutter pub get`.

---

## 🎨 Design System

The app uses a **Neubrutalism** design language:
- Bold black borders
- Hard shadow effects
- Vibrant accent colors (yellow primary, blue, pink, green)
- Monospace typography for data
- Card-based layouts

Color palette defined in `lib/core/theme/neubrut_tokens.dart`.

---

## 📋 Running on Specific Platforms

### Mac (iOS Simulator)
```bash
# Use iPhone 16 Pro Max (iOS 18.6) — NOT iPhone 17
flutter run -d FACDB75A-E658-4394-8FD6-0F74A363878E
```

### Windows (Android Emulator)
```bash
# One-time fix for runanywhere
scripts\setup_android_native_libs.bat

# Then run
flutter run
```

---

## 🧪 Known Issues

1. **RunAnywhere SIGSEGV on iOS Simulator**: The native C++ library has missing symbols (`rac_device_set_callbacks`). The app detects this via FFI probe and skips SDK initialization.

2. **RunAnywhere Android Binaries Missing**: The upstream GitHub releases only contain iOS `.xcframework` files. No Android `.so` files are published.

3. **iOS 26 Simulator Incompatibility**: MLKit and several pods don't support arm64 simulators. Use iOS 18.6 simulators instead.

4. **`EXCLUDED_ARCHS` in Podfile**: Required for MLKit compatibility on x86_64 simulators. Don't remove unless you drop MLKit.
