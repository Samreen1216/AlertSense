# 🚨 AlertSense — AI Environmental Sound Awareness System

> *"Turn important sounds into alerts you can see and feel."*

An AI-powered accessibility Android application built with **Flutter & Dart**, designed specifically for deaf and hard-of-hearing individuals. AlertSense continuously monitors environmental sounds via on-device machine learning, categorizes them by urgency, and delivers multi-sensory feedback through custom vibration rhythms, camera flash strobing, high-contrast visual banners, and full-screen emergency overlays.

---

## 📱 Features & UX Innovations

### 1. 🎯 Live Sound Radar (Showpiece)
- A dynamic circular radar displaying real-time acoustic awareness.
- Concentric distance rings correlate with AI confidence percentage (closer to center = higher confidence).
- Animated rotating sweep line and pulsing category-colored dots with labels and percentages.
- Tap-to-start interaction.

### 2. ⚡ 3-Tier Smart Priority Matrix
- **🔴 HIGH (Life Safety)**: Fire & Smoke Alarms, Emergency Sirens, Glass Breaking.
  - Full-screen pulsing red/orange overlay.
  - Rapid 5Hz camera flash strobe.
  - Multi-burst persistent haptic vibration.
  - Immediate one-tap emergency action cards (I'm Safe, Call 911, Alert Family).
- **🟡 MEDIUM (Important Attention)**: Doorbell, Knocking, Baby Crying.
  - Top actionable heads-up notification.
  - Coded haptic pulse (e.g. ding-dong double tap, 3-knock rhythm).
  - Short visual flash.
- **🟢 LOW (Ambient Awareness)**: Dog Barking, Vehicle Horns, Human Shouting.
  - Discreet status bar notification and radar pulse.

### 3. 🌙 Smart Environmental Profiles
- **🏠 Home Mode**: Comprehensive listening (Doorbell, Baby Crying, Fire Alarm, Knocking).
- **🌙 Sleep Mode**: Minimal black bedside screen with giant clock; strictly filters for critical alarms (Fire, Siren, Baby Crying) with amplified vibration.
- **🌳 Outdoor Mode**: Prioritizes sirens, car horns, and shouting.

### 4. 📳 Custom Vibration Designer
- Allows users to tap out their own vibration rhythm directly on the touch screen.
- Visual timeline with millisecond precision and pulse visualization.
- On-device preview and per-sound category saving.

### 5. 🔇 Intelligent Deduplication & Cooldown
- Prevents notification fatigue: continuous alarms (e.g. fire alarm sounding for minutes) collapse into a single ongoing event with elapsed time tracking rather than hundreds of spam notifications.

### 6. 📊 Alert Insights & Analytics Dashboard
- Interactive charts powered by `fl_chart`:
  - **Top Sound This Week**: Highlighted category with occurrence count.
  - **Alerts by Category**: Color-coded comparative bar chart.
  - **Peak Alert Times**: Morning, Afternoon, Evening, Night breakdown.
  - **7-Day Trend Line**: Weekly acoustic event volume.

### 7. 🎨 Accessibility-First Design
- **4 Built-in Themes**:
  1. Standard Material 3 Light.
  2. Dark Mode.
  3. High Contrast (pure black background with neon accents for low vision).
  4. Color-Blind Accessible (IBM color-safe palette).
- **Font Scaling**: 100%, 125%, 150%, and 200% scaling factors.
- **Touch Target Sizing**: Minimum 48×48dp targets on all interactive elements.

### 8. 🚨 Quick Emergency Actions & Family Uplink
- Pre-configured emergency contacts.
- One-tap "I'm Safe" and "Alert Family" pre-composed SMS messaging via `url_launcher`.
- Direct 911 emergency dialer launcher.

---

## 🏗️ Technical Architecture (Clean Architecture)

```
lib/
├── app.dart                        # MaterialApp, theme configuration, router binding
├── main.dart                       # Entry point, ProviderScope, repository initialization
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Material 3 & accessibility color palettes
│   │   ├── app_strings.dart        # All localized UI strings
│   │   ├── priority_levels.dart    # PriorityLevel enum (High, Medium, Low)
│   │   └── sound_categories.dart   # SoundCategory enum with YAMNet mappings & metadata
│   ├── router/
│   │   └── app_router.dart         # GoRouter declarative navigation with indexed shell
│   ├── theme/
│   │   ├── app_theme.dart          # 4 complete ThemeData builders
│   │   ├── app_typography.dart     # Scaled accessible typography
│   │   └── theme_provider.dart     # Dynamic theme & text scale state
│   └── utils/
│       └── vibration_patterns.dart # Predefined haptic pattern arrays
├── data/
│   ├── datasources/
│   │   └── local_storage.dart      # SharedPreferences persistence layer
│   ├── models/
│   │   ├── alert_event.dart        # Alert entity
│   │   ├── classification_result.dart # AI inference result data
│   │   ├── sound_profile.dart      # Home/Sleep/Outdoor presets
│   │   └── user_settings.dart      # User preferences entity
│   └── repositories/
│       ├── alert_repository.dart   # Alert history CRUD & statistical aggregates
│       └── settings_repository.dart # Preferences & profiles repository
├── providers/
│   ├── alert_providers.dart        # Alert state, filtering & acknowledgment
│   ├── audio_providers.dart        # Live audio state, ambient dB, radar detections
│   ├── settings_providers.dart     # Reactive user settings & sound profiles
│   └── stats_providers.dart        # Chart datasets & trend calculations
├── services/
│   ├── alert_dispatcher_service.dart # Central sensory & logging coordinator
│   ├── audio_stream_service.dart   # 16kHz PCM audio stream capture
│   ├── deduplication_service.dart  # Cooldown & event duration tracking
│   ├── flash_service.dart          # Camera LED flashlight strobe controller
│   ├── notification_service.dart   # Android notification channels (heads-up)
│   ├── priority_engine.dart        # Confidence thresholding & priority mapping
│   ├── sms_service.dart            # Emergency SMS & phone dialing
│   ├── tflite_classifier_service.dart # YAMNet TFLite on-device inference
│   └── vibration_service.dart      # Haptic feedback & custom pattern execution
└── ui/
    ├── alert/                      # Full-screen emergency alert overlay
    ├── history/                    # Filterable alert log with share/export
    ├── home/                       # Sound radar, status bar, toggle grid, profile tabs
    ├── onboarding/                 # 3-step animated setup guide
    ├── settings/                   # Custom vibration, sensitivity, profiles, themes
    ├── shared/                     # Reusable badges, icons, scaffold
    ├── sleep/                      # Minimalist bedtime guardian screen
    └── stats/                      # Interactive insight charts
```

---

## 🚀 Getting Started & Running on Device

### Prerequisites
- Flutter SDK (3.24 or higher)
- Android Studio with Android SDK 34
- Physical Android smartphone running Android 8.0+ (API 26+)
  *(A physical device is required for microphone, hardware vibrator, and camera flash testing)*

### Installation Steps

1. **Open your project directory in terminal:**
   ```bash
   cd "C:\Users\samre\final project"
   ```

2. **Fetch Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **(Optional) Add Real YAMNet TFLite Model:**
   - Download the model from TensorFlow Hub:
     [YAMNet TFLite on TF Hub](https://tfhub.dev/google/lite-model/yamnet/tflite/1)
   - Save the file as `assets/models/yamnet.tflite`.
   - The app automatically runs with built-in interactive simulation mode if the file is absent.

4. **Connect Your Android Phone via USB:**
   - Enable **Developer Options** and **USB Debugging** on your phone.
   - Verify connection:
     ```bash
     flutter devices
     ```

5. **Run the Application:**
   ```bash
   flutter run -d <your-device-id>
   ```

6. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```
   The generated APK will be at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing the App

### Sound Detection Simulation
- In the app, tap the large microphone FAB on the **Home** tab to start listening.
- Watch the **Live Sound Radar** begin rotating.
- Ambient noise decibels (dB) will fluctuate in real time on the status meter.
- Simulated sound events will trigger radar dots and log entries in the **History** tab.

### Testing with Real Sounds
- Play a YouTube clip of a **Fire Alarm** or **Doorbell** near your phone's microphone.
- Check the instant response:
  - **Fire Alarm**: Triggers full-screen pulsing red alert, camera strobe, and strong vibration.
  - **Doorbell**: Triggers top banner notification and pulsed vibration.

---

## 📄 License
Created for Assistive Technology & Accessibility Systems. All rights reserved.
