# 🚨 AlertSense — AI Environmental Sound Awareness System

> **"Turn important sounds into alerts you can see and feel."**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-YAMNet-FF6F00?logo=tensorflow&logoColor=white)](https://tfhub.dev/google/lite-model/yamnet/tflite/1)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20Sync-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%208.0+-3DDC84?logo=android&logoColor=white)](https://android.com)
[![Tests](https://img.shields.io/badge/Tests-432%20Passed-brightgreen)](https://github.com/Samreen1216/AlertSense)
[![License](https://img.shields.io/badge/License-Proprietary%20%2F%20Assistive%20Tech-blue)](LICENSE)

**AlertSense** is an AI-powered environmental sound awareness and emergency notification Android application built with **Flutter & Dart**, tailored specifically for deaf and hard-of-hearing individuals. AlertSense continuously monitors ambient sounds using on-device machine learning (Google's YAMNet architecture), categorizes them by urgency, and delivers immediate multi-sensory feedback through custom vibration rhythms, camera flash strobing, high-contrast visual banners, and full-screen emergency overlays.

---

## 📱 Key Features & UX Innovations

### 1. 🎯 Live Sound Radar & Real-Time Decibel Meter (Hero Showcase)
* **Visual Radar Sweep**: Rotating sweep line with concentric confidence rings (closer to center = higher confidence).
* **Radial Acoustic Pips**: Category-colored pulsing dots positioned by confidence and detection frequency.
* **Ambient Decibel (dB) Meter**: Real-time RMS acoustic pressure gauge with dynamic color shifts (Quiet, Moderate, Loud, Dangerous).
* **One-Tap Control**: Instantly start/pause microphone listening directly from the home header or radar center.

### 2. ⚡ 3-Tier Intelligent Priority Matrix
Every detected sound is evaluated against calibrated confidence thresholds and mapped to a tri-tier urgency model:
* **🔴 HIGH (Life Safety)**: Fire & Smoke Alarms, Emergency Sirens, Glass Breaking.
  * Full-screen pulsing red/orange warning overlay with haptic alarm loop.
  * Rapid 5Hz camera flash strobe via hardware LED torch.
  * Continuous high-intensity haptic pulse train.
  * One-tap Emergency Quick Actions: **"I'm Safe"**, **"Call 911"**, **"Alert Family"** (with live GPS pin).
* **🟡 MEDIUM (Important Attention)**: Doorbell, Door Knocking, Baby Crying.
  * Top actionable heads-up notification banner.
  * Signature coded haptics (e.g. ding-dong double tap, 3-pulse knock cadence).
  * Timed short flash pulse.
* **🟢 LOW (Ambient Awareness)**: Dog Barking, Vehicle Horns, Human Shouting.
  * Discreet radar visualization and status bar notification without disruptive feedback.

### 3. 🧠 Dual-Mode AI Audio Inference Engine
* **On-Device YAMNet Classification**: Runs quantized TensorFlow Lite inference (`yamnet.tflite`) across 521 AudioSet classes mapped to consumer accessibility categories.
* **Acoustic Simulation Mode**: Seamless fallback and demo engine for testing alerts, haptics, and UI responses without requiring specialized sound hardware or loud external noises.

### 4. 🎛️ Digital Signal Processing (DSP) Pipeline
* **Audio Stream Service**: 16,000 Hz, 16-bit linear PCM audio capture via microphone.
* **Audio Preprocessor**: Stereo-to-mono downmixing, Float32 normalization `[-1.0, 1.0]`, and 15,600-sample framing (0.975s window).
* **Acoustic DSP Analyzer**: Fast Fourier Transform (FFT) spectral energy estimation, dominant peak frequency tracking, spectral centroid, and RMS energy calculation.
* **Signal Energy Validator**: Dynamic noise floor calibration and SNR (Signal-to-Noise Ratio) gating to filter out low-energy mic noise and electrical hums.
* **Temporal Smoothing & Hysteresis**: Sliding window probability smoother with hysteresis thresholds to suppress false triggers and fluttering classifications.

### 5. 🔇 Smart Cooldown & Deduplication
* Prevents alert fatigue: Continuous alarms (e.g., a siren wailing for 5 minutes) collapse into an ongoing single alert with accumulated duration rather than firing hundreds of duplicate notifications.

### 6. 📳 Custom Vibration Designer & Hardware Haptics
* **Interactive Tap Recorder**: Users can tap custom rhythms onto the touchscreen with real-time waveform recording.
* **Millisecond Precision**: Records exact pulse and pause arrays for tactile playback.
* **Preset Haptic Library**: Distinct rhythmic signatures for fire alarms, doorbells, knocks, baby cries, and footsteps.
* **Sleep Boost**: Amplified vibration amplitude override during bedtime mode.

### 7. 📍 Emergency Lifeline & GPS SOS Uplink
* **Live GPS Location Tracking**: High-accuracy latitude, longitude, and accuracy radius via `geolocator`.
* **Automated SOS SMS**: Formats urgent text messages containing Google Maps pin links (`https://maps.google.com/?q=lat,lng`) dispatched to saved emergency contacts.
* **Direct Emergency Dialer**: Launches telephone dialer with prefilled emergency service numbers (`911` / local emergency).
* **WhatsApp Dispatch**: Formatted one-tap emergency text transmission.

### 8. 🌙 Smart Environmental Profiles
* **🏠 Home Profile**: Balanced monitoring for daily domestic sounds (Doorbell, Baby Crying, Fire Alarm, Knocking).
* **🌙 Sleep / Nightstand Mode**: Ultra-minimal pure black bedside clock with giant legible time display; strictly filters for critical alarms (Fire, Siren, Baby Crying) with maximum haptic intensity.
* **🌳 Outdoor Profile**: Filters out background street noise while boosting sirens, vehicle horns, and shouts.
* **Profile Editor**: Customize detection sensitivities and enable/disable individual sounds per profile.

### 9. 📲 Android Home Screen AppWidget
* Powered by `home_widget` and Kotlin `AlertSenseWidgetProvider`.
* Displays real-time listening status, current profile, ambient sound level, and last detected alert directly on the Android home screen.
* One-tap interactive launch directly into the relevant app section.

### 10. 📊 Alert Insights Dashboard & PDF Incident Reports
* **Interactive Visual Analytics**: Built with `fl_chart`:
  * Top detected sound with weekly count.
  * Category breakdown comparative bar chart.
  * Hourly time-of-day distribution (Morning, Afternoon, Evening, Night).
  * 7-day alert volume trend line.
* **Production-Grade PDF Export**: Generates and shares professional, formatted incident report PDFs (`pdf` and `share_plus`) complete with summary KPIs, timestamps, dB levels, and verification status.

### 11. 🔐 Supabase Cloud Authentication & User Security
* **Authentication Flows**: Email/password sign-up, sign-in, and verification.
* **PKCE Deep Linking**: Password recovery and email confirmation handled via deep links (`alertsense://auth-callback`).
* **Profile Management**: User profile customization, password update dialogs, and safe account deletion with safety checkboxes.

### 12. 🎨 Accessibility-First Design
* **4 Built-in Color Themes**:
  1. Material 3 Light Mode
  2. Dark Mode
  3. High Contrast Mode (pure `#000000` pitch black with `#FFD600` neon yellow accents)
  4. Color-Blind Safe Mode (IBM accessibility palette)
* **Scalable Typography**: Dynamic text scaling support (1.0x, 1.25x, 1.5x, 2.0x) with zero layout overflow.
* **48dp Touch Targets**: Compliant with Android accessibility touch guidelines.
* **Foreground Service**: Continuous background listening with notification channel controls and battery optimization guidance.

---

## 🏗️ Architecture & Project Structure

AlertSense adheres to **Clean Architecture** with strict layer separation and **Riverpod** state management:

```
lib/
├── app.dart                                # MaterialApp, GoRouter bindings, theme configuration
├── main.dart                               # Entry point, ProviderScope, services bootstrap
│
├── core/                                   # Shared kernel & core utilities
│   ├── config/
│   │   └── supabase_config.dart            # Supabase credentials & PKCE configuration
│   ├── constants/
│   │   ├── app_assets.dart                 # Asset paths (icons, model files)
│   │   ├── app_colors.dart                 # Color palettes (Light, Dark, High Contrast, Color-Blind)
│   │   ├── app_svg_icons.dart              # Custom vector SVG icons
│   │   ├── priority_levels.dart            # High, Medium, Low urgency definitions
│   │   ├── sound_categories.dart           # Sound categories & YAMNet mapping
│   │   └── sound_detection_thresholds.dart # Default sensitivity threshold constants
│   ├── router/
│   │   └── app_router.dart                 # Declarative GoRouter configuration with auth guards
│   ├── theme/
│   │   ├── app_theme.dart                  # ThemeData definitions for all 4 themes
│   │   ├── app_typography.dart             # Accessible scalable typography
│   │   └── theme_provider.dart             # Reactive theme state & text scale notifier
│   └── utils/
│       ├── auth_validators.dart            # Email normalization & password strength checks
│       ├── responsive_utils.dart           # Tablet/desktop breakpoints & layout helpers
│       └── vibration_patterns.dart         # Hardware haptic rhythm timings
│
├── data/                                   # Data layer (models, datasources, repositories)
│   ├── datasources/
│   │   ├── local_storage.dart              # SharedPreferences local persistence
│   │   └── supabase_auth_datasource.dart   # Supabase client authentication gateway
│   ├── models/
│   │   ├── alert_event.dart                # Acoustic event entity & serialization
│   │   ├── classification_result.dart      # Inference prediction data container
│   │   ├── sound_profile.dart              # Environmental profile configuration model
│   │   ├── user_profile.dart               # User identity & settings entity
│   │   └── user_settings.dart              # Vibration, sensitivity, & notification preferences
│   └── repositories/
│       ├── alert_repository.dart           # Alert history CRUD & statistical aggregations
│       ├── auth_repository.dart            # User authentication state & session management
│       └── settings_repository.dart        # User preferences & profile persistence
│
├── evaluation/                             # AI model offline validation framework
│   ├── evaluation_engine.dart              # Batch audio evaluation runner & metrics calculator
│   └── evaluation_models.dart              # Precision, recall, F1-score & confusion matrix
│
├── providers/                              # Riverpod state notifiers & business logic
│   ├── alert_providers.dart                # Active alerts, history filtering, acknowledgment
│   ├── audio_providers.dart                # Audio stream status, live dB, radar detections
│   ├── auth_providers.dart                 # Authentication state, login/signup forms, session
│   ├── device_providers.dart               # Battery level & hardware capabilities
│   ├── quick_scan_provider.dart            # Real-time room acoustic scanner state
│   ├── service_providers.dart              # Dependency injection for singletons & services
│   ├── settings_providers.dart             # Reactive user preferences & sound profiles
│   └── stats_providers.dart                # Chart analytics & weekly aggregations
│
├── services/                               # Hardware & low-level platform integrations
│   ├── acoustic_dsp_analyzer.dart          # FFT spectral analysis & peak frequency detection
│   ├── alert_dispatcher_service.dart       # Central orchestrator: audio -> AI -> haptics/flash
│   ├── audio_preprocessor.dart             # PCM16 to Float32 conversion & window framing
│   ├── audio_stream_service.dart           # Microphone PCM capture & RMS dB calculation
│   ├── deduplication_service.dart          # Cooldown timers & continuous event aggregation
│   ├── device_service.dart                 # Battery state & device hardware inspection
│   ├── flash_service.dart                  # Camera LED strobe controller (5Hz pulsing)
│   ├── foreground_service.dart             # Android foreground service execution
│   ├── home_widget_service.dart            # Home Screen AppWidget synchronization
│   ├── location_service.dart               # GPS coordinate retrieval & Google Maps linking
│   ├── notification_service.dart           # Android notification channels (High/Med/Low)
│   ├── pdf_export_service.dart             # PDF report layout, compilation, and sharing
│   ├── priority_engine.dart                # Confidence evaluation & priority mapping
│   ├── signal_energy_validator.dart        # Noise floor calibration & SNR gating
│   ├── sms_service.dart                    # Emergency SMS & phone dialing dispatch
│   ├── temporal_smoothing_service.dart     # Sliding window smoothing & hysteresis logic
│   ├── tflite_classifier_service.dart      # YAMNet TFLite on-device inference
│   └── vibration_service.dart              # Hardware haptics & custom rhythm player
│
└── ui/                                     # Presentation layer (screens & widgets)
    ├── alert/                              # Full-screen emergency alert & emergency dialogs
    │   ├── alert_details_screen.dart       # Detailed alert view with timestamps and maps
    │   ├── full_screen_alert.dart          # High-priority pulsing overlay screen
    │   ├── dialogs/                        # Call 911, SMS SOS, and WhatsApp share dialogs
    │   └── widgets/                        # Action buttons & response cards
    ├── auth/                               # Authentication screens
    │   ├── login_screen.dart               # User login with validation
    │   ├── signup_screen.dart              # Registration with password checklist
    │   ├── forgot_password_screen.dart     # Password recovery email trigger
    │   ├── reset_password_screen.dart      # Password update screen from deep link
    │   ├── email_verification_screen.dart  # Email confirmation status screen
    │   └── widgets/                        # Shared auth headers, inputs, buttons
    ├── history/                            # Alert history log with filtering & PDF export
    ├── home/                               # Main dashboard screen
    │   ├── home_screen.dart                # Responsive Home screen layout
    │   └── widgets/                        # Radar, header, listening card, category cards
    ├── onboarding/                         # 3-step accessible onboarding setup guide
    ├── quick_scan/                         # Ambient room acoustic scanner
    ├── settings/                           # Settings, contacts, profiles, custom vibrations
    ├── shared/                             # Reusable scaffolds, badges, banners, icons
    ├── sleep/                              # Bedside sleep mode & nightstand clock
    ├── splash/                             # Splash screen with auth state resolution
    ├── stats/                              # Interactive charts & trend analytics
    └── widget/                             # Android Home Widget configuration showcase
```

---

## 🧰 Tech Stack & Dependencies

| Category | Libraries / Frameworks |
|---|---|
| **Core Framework** | Flutter SDK (3.24+), Dart (3.5+) |
| **State Management** | `flutter_riverpod`, `riverpod_annotation`, `rxdart` |
| **Navigation** | `go_router` (Stateful Shell, Deep Links, Auth Guards) |
| **AI & Audio** | `tflite_flutter` (YAMNet), `record` (PCM Stream) |
| **Hardware & Alerts** | `vibration`, `torch_light`, `flutter_local_notifications`, `flutter_foreground_task` |
| **Location & SOS** | `geolocator`, `url_launcher`, `permission_handler` |
| **Cloud & Auth** | `supabase_flutter` (PKCE Auth, Session Recovery) |
| **Reporting & Export** | `pdf`, `share_plus`, `intl` |
| **Android Widget** | `home_widget` |
| **UI & Styling** | `fl_chart`, `flutter_animate`, `flutter_svg`, `google_fonts`, `shimmer` |
| **Testing** | `flutter_test`, `flutter_lints` (432 automated tests) |

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.24.0` or higher
* **Dart SDK**: `^3.5.0`
* **Android Studio**: Android SDK Build-Tools 34, Android NDK
* **Target Device**: Physical Android device running Android 8.0+ (API 26+)
  *(Microphone audio recording, camera LED flashlight strobe, and hardware haptic vibrator require a physical Android device)*

---

### Installation & Run Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Samreen1216/AlertSense.git
   cd AlertSense
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase Credentials (Optional for Custom Backend):**
   AlertSense has default sandbox configuration built-in. To point to your own Supabase instance, supply environment flags at build/run time:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

4. **Verify YAMNet Model & Labels:**
   The TFLite model and class mappings are located in:
   * `assets/models/yamnet.tflite`
   * `assets/labels/yamnet_class_map.csv`
   *(If the model file is not present, the app automatically switches to built-in simulation mode).*

5. **Connect Android Device via USB:**
   * Enable **Developer Options** and **USB Debugging** on your phone.
   * Verify detection:
     ```bash
     flutter devices
     ```

6. **Run the Application:**
   ```bash
   flutter run -d <device-id>
   ```

7. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing & Code Quality

AlertSense includes a comprehensive automated test suite spanning unit tests, audio preprocessors, DSP analyzers, location services, auth workflows, responsiveness, and accessibility:

```bash
# Run all 432 unit, widget, and integration tests
flutter test

# Run static code analysis
flutter analyze
```

### Test Coverage Highlights
* **Authentication Flows**: Email validation, password rules, recovery links, deep-link navigation.
* **Audio & DSP**: PCM16 to Float32 conversion, window framing, FFT peak detection, SNR thresholding, temporal smoothing, hysteresis.
* **Alert System**: Priority engine matrix, deduplication cooldowns, camera strobe dispatch, custom vibration player.
* **Accessibility & UI**: Responsive layouts across small phones (320x568) and tablets (800x1280), landscape orientation, 2.0x font scaling without overflow, and high-contrast theming.

---

## 🔒 Android Hardware Permissions

The app utilizes the following Android permissions declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Purpose |
|---|---|
| `RECORD_AUDIO` | Continuous environmental acoustic capture for on-device AI inference. |
| `VIBRATE` | Tactile sensory feedback for deaf and hard-of-hearing users. |
| `CAMERA` / `FLASHLIGHT` | Hardware camera LED flash strobing on urgent alerts. |
| `FOREGROUND_SERVICE` | Uninterrupted background listening when the app is minimized. |
| `POST_NOTIFICATIONS` | Android heads-up emergency notification dispatch. |
| `ACCESS_FINE_LOCATION` | Real-time GPS coordinates attached to emergency SOS dispatches. |
| `SEND_SMS` / `CALL_PHONE` | Direct lifeline dispatch to saved emergency contacts and 911. |

---

## 📄 License & Attribution
AlertSense was designed and developed as an Assistive Technology & Accessibility solution for deaf and hard-of-hearing individuals.  
All rights reserved © 2026.
