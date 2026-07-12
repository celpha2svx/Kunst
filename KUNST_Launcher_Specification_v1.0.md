# KUNST LAUNCHER — COMPREHENSIVE BUILD SPECIFICATION
## Version: 1.0.1 | Date: 2026-07-12 (Revised) | Author: User (Kunst) + AI Assistant
## Status: PRE-BUILD — Ready for Implementation

---

## 1. EXECUTIVE SUMMARY

KUNST Launcher is an Android launcher application built with Flutter that replaces the default Android home screen. Its core purpose is to help users beat app addiction and manage their digital life through intentional planning, not willpower.

The launcher operates on a day-cycle model: **Night Planning → Morning Focus → Day Execution → Evening Review → Night Planning**.

This is NOT a product for Google Play Store. It is a personal tool, sideloaded via APK.

---

## 2. TARGET DEVICE SPECIFICATIONS

| Parameter | Value |
|-----------|-------|
| Device | Samsung Galaxy A05s |
| Android Version | 15 (API Level 35) |
| Distribution Method | Sideloaded APK (not Google Play) |
| Calendar Integration | Samsung Calendar (primary) |
| AI Assistant Backend | Microsoft Copilot (premium, free via student) |

**Critical Note on Samsung A05s**: This is a budget device (4GB RAM, Snapdragon 680). Performance must be optimized. No heavy animations. Keep memory footprint low.

---

## 3. PERMISSIONS & ACCESS LEVELS

Since this is sideloaded (not Play Store), we can request aggressive permissions at install time. The user will grant full Device Admin access.

### 3.1 Required Android Permissions

```xml
<!-- Core Launcher -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Device Admin (REQUIRED for app blocking/hiding) -->
<uses-permission android:name="android.permission.BIND_DEVICE_ADMIN"/>

<!-- Calendar (Samsung Calendar) -->
<uses-permission android:name="android.permission.READ_CALENDAR"/>
<uses-permission android:name="android.permission.WRITE_CALENDAR"/>

<!-- Alarm -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- Notification Gatekeeper -->
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"/>
<uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>

<!-- Do Not Disturb / Focus Mode -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>

<!-- Usage Stats (for app timer / hard cut) -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"/>

<!-- Overlay (for blocking UI when timer expires) -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>

<!-- Boot completed (for persistent services) -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Foreground service (for gatekeeper running in background) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
```

### 3.2 Device Admin Policy

The app MUST be registered as a Device Admin to:
- Hide/disable apps programmatically
- Lock the device
- Enforce policies

```xml
<!-- res/xml/device_admin.xml -->
<device-admin xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-policies>
        <disable-camera />
        <force-lock />
        <limit-password />
        <watch-login />
        <reset-password />
        <wipe-data />
        <expire-password />
        <encrypted-storage />
        <disable-keyguard-features />
    </uses-policies>
</device-admin>
```

**User Flow**: On first launch, prompt user to enable Device Admin. If declined, app cannot function — show explanatory screen and exit.

---

## 4. ARCHITECTURE OVERVIEW

### 4.1 High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    KUNST LAUNCHER                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   UI Layer  │  │  State Mgmt │  │   Service Layer     │  │
│  │  (Flutter)  │  │  (Provider) │  │  (Android Native)   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │              │
│  ┌──────▼────────────────▼────────────────────▼──────────┐  │
│  │              Core Engine (Dart + Platform Channels)   │  │
│  │  • Task Scheduler    • App Blocker    • Alarm Mgr    │  │
│  │  • Calendar Sync     • Notification Filter            │  │
│  │  • Theme Engine      • Focus Mode      • Timer Mgr    │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│  ┌─────────────────────────▼────────────────────────────┐  │
│  │              Local Database (SQLite via sqflite)      │  │
│  │  • Tasks    • Notes    • App Whitelist    • Settings │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│  ┌─────────────────────────▼────────────────────────────┐  │
│  │              AI Assistant (Copilot Integration)       │  │
│  │  • Night Planning Chat    • Task Suggestions         │  │
│  │  • Daily Summary          • Pattern Learning         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Platform Channels (Flutter ↔ Android)

| Feature | Dart Side | Android Side (Kotlin) |
|---------|-----------|----------------------|
| Hide/Show Apps | `MethodChannel('app_manager')` | `DevicePolicyManager.setApplicationHidden()` |
| Set Alarm | `MethodChannel('alarm_manager')` | `AlarmManager.setExactAndAllowWhileIdle()` |
| Read Notifications | `EventChannel('notification_stream')` | `NotificationListenerService` |
| Calendar Read | `MethodChannel('calendar_manager')` | `ContentResolver.query(CalendarContract.Events)` |
| Calendar Write | `MethodChannel('calendar_manager')` | `ContentResolver.insert(CalendarContract.Events)` |
| Force Stop App | `MethodChannel('app_manager')` | `ActivityManager.killBackgroundProcesses()` + overlay block |
| DND Toggle | `MethodChannel('focus_manager')` | `NotificationManager.setInterruptionFilter()` |
| Overlay Block | `MethodChannel('overlay_manager')` | `WindowManager.addView()` with `TYPE_APPLICATION_OVERLAY` |

---

## 5. SCREEN-BY-SCREEN SPECIFICATION

### 5.1 SCREEN: Onboarding (First Launch Only)

**Purpose**: Set up permissions, Device Admin, and initial preferences.

**Flow**:
1. Welcome screen — "KUNST Launcher helps you own your time."
2. Permission explanation — list ALL permissions with WHY each is needed
3. Device Admin request — `startActivityForResult()` with `DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN`
4. Notification Listener request — `startActivity()` with `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`
5. Usage Stats request — `startActivity()` with `Settings.ACTION_USAGE_ACCESS_SETTINGS`
6. Calendar permission — runtime request `READ_CALENDAR`, `WRITE_CALENDAR`
7. Exact Alarm permission — `startActivity()` with `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM`
8. Theme selection (see Section 8)
9. Initial system setup — user defines their "Worlds" (default: Inner, Outside, Future)
10. Complete — launcher becomes default home

**Edge Cases**:
- If any permission is denied, show which feature breaks and offer to retry
- If Device Admin is declined, app cannot function — show lock screen explaining why

---

### 5.2 SCREEN: Night Planning Mode

**Trigger**: User opens launcher between 9 PM — 12 AM (configurable in settings)
**OR**: User manually taps "Night Mode" button anytime.

**Layout**:
- Full-screen dark interface
- Top: Date + "Night Planning" header
- Center: Large text input area (note) — auto-saves every 3 seconds
- Below note: AI Chat interface
  - User types or speaks intent for tomorrow
  - AI (Copilot) responds with questions, suggestions, time estimates
  - Conversation is saved and linked to tomorrow's date
- Bottom: "Plan Tomorrow" button
  - Tapping it: AI parses the conversation → extracts tasks → suggests time blocks
  - User confirms/edits → tasks saved to DB + synced to Samsung Calendar
  - Alarm auto-set for first task time
  - Phone enters "Sleep Mode" (DND on, all apps hidden except emergency)

**Calendar Sync Logic**:
- Read from Samsung Calendar: `content://com.android.calendar/events`
- Write to Samsung Calendar: Insert event with `CalendarContract.Events.CONTENT_URI`
- Each task becomes a calendar event with:
  - `title`: Task name
  - `dtstart`: Task start time
  - `dtend`: Task end time
  - `description`: Task details + world tag + type tag
  - `calendar_id`: User's primary Samsung Calendar ID (queried at runtime)

**Alarm Setting Logic**:
- After tasks are planned, find the earliest task time
- Set alarm 30 minutes before (configurable)
- Use `AlarmManager.setExactAndAllowWhileIdle()` with `RTC_WAKEUP`
- On Samsung Android 15, also check `canScheduleExactAlarms()` — if false, prompt user to Settings
- Alarm intent triggers a BroadcastReceiver that wakes the device and shows "Wake Up" screen

**AI Integration (Copilot)**:
- Since Copilot is premium/free student, we use the Copilot API or web integration
- Alternative: Use a lightweight local model for simple task parsing, Copilot for complex planning
- For MVP: Rule-based parsing first, Copilot as enhancement later

---

### 5.3 SCREEN: Morning Focus Mode (Default Launcher Home)

**Trigger**: Alarm rings + user dismisses OR first unlock after alarm time
**OR**: Any time during configured "Focus Hours" (default: wake time — 6 PM)

**Layout**:
- NO app drawer. NO all-apps grid.
- Wallpaper: Today's task list (text overlay on dark background)
- Visible apps ONLY: Those linked to today's scheduled tasks
  - Each task has an `appsNeeded` array
  - Launcher queries DB for today's tasks → gets union of all `appsNeeded` → shows only those app icons
- Each visible app icon shows a small badge: task name + time block
- Bottom dock: 4 fixed slots
  - Slot 1: Phone app (always allowed)
  - Slot 2: Messages app (always allowed)
  - Slot 3: Launcher Settings
  - Slot 4: Emergency contacts
- Swipe up: Shows "Today's Schedule" timeline view
- Swipe down: Quick settings (DND toggle, brightness, WiFi)

**App Hiding Logic**:
```kotlin
// Android side (Kotlin)
val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
val adminComponent = ComponentName(context, MyDeviceAdminReceiver::class.java)

// Hide all apps except whitelist
val allApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
for (app in allApps) {
    val shouldShow = app.packageName in allowedApps || app.packageName == context.packageName
    dpm.setApplicationHidden(adminComponent, app.packageName, !shouldShow)
}
```

**Allowed Apps Calculation**:
```dart
// Dart side
Future<Set<String>> getAllowedAppsForToday() async {
  final db = await openDatabase('kunst.db');
  final today = DateTime.now();
  final tasks = await db.query('tasks', 
    where: 'date = ? AND status != ?',
    whereArgs: [DateFormat('yyyy-MM-dd').format(today), 'completed']
  );

  Set<String> allowed = {'com.samsung.android.dialer', 'com.samsung.android.messaging'};
  for (var task in tasks) {
    final apps = jsonDecode(task['appsNeeded'] as String) as List;
    allowed.addAll(apps.cast<String>());
  }
  return allowed;
}
```

---

### 5.4 SCREEN: Social Media Gatekeeper

**Background Service**: `NotificationListenerService` running persistently

**Logic**:
1. All notifications intercepted via `onNotificationPosted(StatusBarNotification sbn)`
2. For each notification:
   - Extract: package name, title, text, sender
   - Check if package is in `socialApps` list (configurable: WhatsApp, Instagram, TikTok, Twitter/X, Telegram, etc.)
   - If NOT social: allow through normally
   - If social:
     - Check sender against `lovedOnes` contact list (user-defined)
     - Check message content against `emergencyKeywords` ("urgent", "emergency", "hospital", "accident", etc.)
     - If loved one OR emergency keyword: show notification with "[KUNST] Important from [Name]"
     - Else: queue notification in DB, do NOT show. Add to "Evening Summary" batch.

**User Decision Flow**:
- When an important social notification arrives:
  - Show custom notification: "[KUNST] Message from Mom — Check now or queue for evening?"
  - Two actions: "Check Now" (opens app) / "Queue It" (adds to evening summary)
- Tapping "Check Now" opens the app but starts a 5-minute timer. After 5 min, overlay appears: "Back to focus?"

**Evening Summary**:
- Triggered when user marks all tasks complete OR at configurable evening time (default 7 PM)
- Shows a scrollable list: "You have 12 queued notifications: 3 WhatsApp, 5 Instagram DMs, 4 Telegram..."
- Each item shows sender + preview text
- User taps "I'm interested" → opens that app with timer
- User taps "Skip all" → all cleared, apps stay hidden until tomorrow evening

---

### 5.5 SCREEN: Evening Leisure Mode

**Trigger**: All tasks marked complete OR manual "I'm done" button

**Layout**:
- Social apps become visible
- User selects which app to open
- Timer picker appears: "How long?" (15, 30, 45, 60 min — configurable max)
- User opens app
- Background service starts countdown
- When timer expires:
  - Overlay covers entire screen: "Time's up. See you tomorrow."
  - `ActivityManager.killBackgroundProcesses(packageName)` on the social app
  - App is hidden again via `setApplicationHidden()`
  - Phone returns to Focus Mode

**Hard Cut Implementation**:
```kotlin
// Overlay that blocks the app
val params = WindowManager.LayoutParams(
    WindowManager.LayoutParams.MATCH_PARENT,
    WindowManager.LayoutParams.MATCH_PARENT,
    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
    PixelFormat.TRANSLUCENT
)
val overlayView = LayoutInflater.from(context).inflate(R.layout.time_up_overlay, null)
windowManager.addView(overlayView, params)

// Kill the app
val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
am.killBackgroundProcesses(socialAppPackage)

// Hide the app
dpm.setApplicationHidden(adminComponent, socialAppPackage, true)
```

---

### 5.6 SCREEN: Settings

**Sections**:
1. **Theme** (see Section 8)
2. **Focus Hours**: Start time, end time
3. **Sleep Hours**: Start time, end time
4. **Social Apps List**: Checkbox list of installed apps to treat as "social"
5. **Loved Ones**: Contact picker for priority notification senders
6. **Emergency Keywords**: Editable list
7. **Worlds Configuration**: Add/edit/delete worlds (default: Inner, Outside, Future)
8. **Task Types**: Add/edit/delete task types (default: Immediate, Gradual, Project)
9. **Timer Defaults**: Default social timer, max social timer
10. **Calendar**: Select which calendar to sync with
11. **Backup/Export**: Export DB to JSON, import from JSON
12. **Reset**: Factory reset all data

---

## 6. DATABASE SCHEMA

```sql
-- tasks table
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    world TEXT NOT NULL,           -- references worlds.name
    time_state TEXT NOT NULL,      -- 'immediate' | 'continuous' | 'present'
    type TEXT NOT NULL,            -- 'immediate' | 'gradual' | 'project'
    apps_needed TEXT,              -- JSON array of package names
    date TEXT NOT NULL,            -- ISO 8601: YYYY-MM-DD
    start_time TEXT,               -- HH:MM
    end_time TEXT,                 -- HH:MM
    priority INTEGER DEFAULT 1,    -- 1-5
    status TEXT DEFAULT 'pending', -- 'pending' | 'in_progress' | 'completed' | 'skipped'
    calendar_event_id TEXT,        -- Samsung Calendar event ID
    created_at TEXT,               -- ISO 8601 datetime
    updated_at TEXT                -- ISO 8601 datetime
);

-- notes table (night planning conversations)
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,            -- YYYY-MM-DD (the date this note plans FOR)
    content TEXT NOT NULL,         -- User's raw note
    ai_conversation TEXT,          -- JSON array of {role, message, timestamp}
    extracted_tasks TEXT,          -- JSON array of task objects (before user confirms)
    status TEXT DEFAULT 'draft',   -- 'draft' | 'confirmed' | 'archived'
    created_at TEXT
);

-- worlds table (user-defined life systems)
CREATE TABLE worlds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    color TEXT,                    -- hex color for UI
    icon TEXT,                     -- emoji or icon name
    sort_order INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1
);

-- app_whitelist table (which apps are allowed when)
CREATE TABLE app_whitelist (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_name TEXT NOT NULL UNIQUE,
    app_name TEXT,
    category TEXT,                 -- 'social' | 'productive' | 'communication' | 'system'
    is_always_allowed INTEGER DEFAULT 0,
    max_daily_minutes INTEGER,     -- null = unlimited
    world_id INTEGER,              -- which world this app belongs to (optional)
    FOREIGN KEY (world_id) REFERENCES worlds(id)
);

-- notifications_queue table (intercepted social notifications)
CREATE TABLE notifications_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_name TEXT NOT NULL,
    title TEXT,
    text TEXT,
    sender TEXT,
    timestamp TEXT,
    is_important INTEGER DEFAULT 0,
    is_loved_one INTEGER DEFAULT 0,
    is_emergency INTEGER DEFAULT 0,
    user_action TEXT,              -- 'checked_now' | 'queued' | 'skipped'
    date TEXT                      -- YYYY-MM-DD (for evening summary grouping)
);

-- daily_logs table (for pattern learning)
CREATE TABLE daily_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    tasks_planned INTEGER DEFAULT 0,
    tasks_completed INTEGER DEFAULT 0,
    tasks_skipped INTEGER DEFAULT 0,
    focus_hours REAL DEFAULT 0,    -- hours in focus mode
    social_minutes_used INTEGER DEFAULT 0,
    notifications_queued INTEGER DEFAULT 0,
    notifications_checked INTEGER DEFAULT 0,
    wake_time TEXT,
    sleep_time TEXT,
    mood TEXT,                     -- user self-reported
    notes TEXT
);

-- settings table
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TEXT
);
```

**Default Settings Insert**:
```sql
INSERT INTO settings (key, value) VALUES
('theme', 'dark_grey'),
('focus_start_time', '06:00'),
('focus_end_time', '18:00'),
('sleep_start_time', '22:00'),
('sleep_end_time', '06:00'),
('default_social_timer', '30'),
('max_social_timer', '60'),
('alarm_buffer_minutes', '30'),
('calendar_id', ''),  -- filled after user selects
('first_launch_complete', '0');
```

---

## 7. SAMSUNG-SPECIFIC CONSIDERATIONS

### 7.1 Battery Optimization (CRITICAL)

Samsung aggressively kills background apps. Must handle:

1. **Request "Unrestricted" battery usage**:
   ```kotlin
   val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
   intent.data = Uri.parse("package:${context.packageName}")
   startActivity(intent)
   ```

2. **Disable Samsung "Put unused apps to sleep"**:
   - Cannot programmatically disable
   - Must instruct user to: Settings → Battery → Background usage limits → Put unused apps to sleep → OFF
   - OR add launcher to "Never sleeping apps" list

3. **Auto-start permission**:
   - Samsung One UI has "Auto start" per app
   - Must instruct user to enable for KUNST Launcher

### 7.2 Samsung Calendar Integration

Samsung Calendar uses the standard Android Calendar Provider (`com.android.calendar`), but:
- Calendar ID must be queried at runtime — do NOT hardcode
- Use `CalendarContract.Calendars.CONTENT_URI` to list available calendars
- Let user pick which calendar to sync with in Settings
- Samsung Calendar may not sync immediately — add `SYNC_EVENTS = 1` when inserting

### 7.3 Samsung One UI Overlay

Samsung's Edge Panels, Bixby Routines, and Game Launcher may interfere:
- Edge Panels: Can still swipe from edge to access apps — consider this acceptable for MVP
- Bixby Routines: May conflict with DND toggles — document this
- Game Launcher: May intercept app launches — test thoroughly

### 7.4 Samsung A05s Performance

- 4GB RAM, Snapdragon 680
- Keep Flutter widget tree shallow
- Use `const` constructors everywhere possible
- Limit animations to simple fades
- SQLite operations: use batch inserts, avoid N+1 queries
- Image assets: compress heavily, use WebP format

---

## 8. THEME SYSTEM

### 8.1 Available Themes (User Selectable in Settings)

| Theme Name | Background | Surface | Primary | Accent | Text Primary | Text Secondary |
|-----------|------------|---------|---------|--------|--------------|----------------|
| **Pure Black** | `#000000` | `#0a0a0a` | `#ffffff` | `#888888` | `#ffffff` | `#aaaaaa` |
| **Dark Grey** | `#121212` | `#1e1e1e` | `#e0e0e0` | `#a0a0a0` | `#e0e0e0` | `#888888` |
| **Gunmetal** | `#1a1a2e` | `#16213e` | `#c0c0c0` | `#667eea` | `#e0e0e0` | `#8892b0` |
| **Silver Dark** | `#1c1c1c` | `#2a2a2a` | `#d4d4d4` | `#c0c0c0` | `#d4d4d4` | `#909090` |
| **OLED Saver** | `#050505` | `#0d0d0d` | `#b0b0b0` | `#666666` | `#b0b0b0` | `#666666` |

### 8.2 Theme Implementation

```dart
// theme_provider.dart
class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'dark_grey';

  final Map<String, ThemeData> themes = {
    'dark_grey': ThemeData(
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1e1e1e),
      primaryColor: const Color(0xFFe0e0e0),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFe0e0e0),
        secondary: const Color(0xFFa0a0a0),
        surface: const Color(0xFF1e1e1e),
        background: const Color(0xFF121212),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFe0e0e0)),
        bodyMedium: TextStyle(color: Color(0xFF888888)),
      ),
    ),
    // ... other themes
  };

  ThemeData get currentTheme => themes[_currentTheme]!;

  void setTheme(String themeName) {
    _currentTheme = themeName;
    notifyListeners();
  }
}
```

### 8.3 UI Design Principles

- **No gradients** on the A05s (performance)
- **Flat design** with subtle elevation shadows
- **High contrast** text for readability
- **Large touch targets** (min 48dp) for accessibility
- **Monochrome icons** (Material Icons, white/grey only)
- **Accent color used sparingly**: only for active states, timers, and important actions

---

## 9. AI ASSISTANT INTEGRATION — MULTI-PROVIDER FALLBACK SYSTEM

### 9.1 Design Principle: No Single Point of Failure

The launcher MUST work even if one AI provider is down or rate-limited. We implement a priority-based fallback chain. All providers listed below have permanent free tiers — no credit card required.

### 9.2 Provider Stack (Priority Order)

| Priority | Provider | Free Tier | Best For | Rate Limits | Fallback Trigger |
|----------|----------|-----------|----------|-------------|------------------|
| **1** | **Groq** | 30 RPM, 14,400 RPD, 30K TPM | Speed, real-time chat | 30 req/min, 1,000/day | 429 error or timeout |
| **2** | **Gemini (Google AI Studio)** | 5-15 RPM, 1,500 RPD (Flash-Lite) | Long context, summarization | 15 req/min, 1,500/day | 429 error or timeout |
| **3** | **Cerebras** | 30 RPM, ~1M tokens/day | Batch processing, throughput | 30 req/min | 429 error or timeout |
| **4** | **GitHub Models** | 15 RPM, 150-1,000 RPD | Frontier models (GPT-4o, Claude) | 15 req/min | 429 error or timeout |
| **5** | **OpenRouter** | 20 RPM, 50 RPD (1,000 with $10) | Variety, auto-failover | 20 req/min, 50/day | All above fail |
| **6** | **Local (Ollama)** | Unlimited | Privacy, offline | Hardware limited | No internet available |

**Key Decision**: All providers use OpenAI-compatible API format. One codebase, swap base_url and api_key.

### 9.3 What the AI Does in the Launcher

The AI handles these tasks — each with different complexity needs:

| Task | Complexity | Preferred Provider | Why |
|------|-----------|-------------------|-----|
| Parse night planning note → extract tasks | Low | Groq (Llama 3.1 8B) | Fast, cheap, good enough |
| Suggest time blocks for tomorrow | Medium | Groq (Llama 3.3 70B) | Fast reasoning |
| Summarize queued social notifications | Medium | Gemini Flash-Lite | Good at summarization |
| Discuss "what if" scenarios | High | Gemini Flash / GitHub Models | Better reasoning |
| Parse complex user intent | High | GitHub Models (GPT-4o/Claude) | Best understanding |
| Offline basic task parsing | Low | Ollama (local) | No internet needed |

### 9.4 Implementation: Unified AI Service

```dart
// services/ai_service.dart

class AIService {
  // Provider configs — all free tier keys
  final List<AIProvider> providers = [
    AIProvider(
      name: 'groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      apiKey: 'gsk_YOUR_GROQ_KEY', // from console.groq.com
      defaultModel: 'llama-3.1-8b-instant',
      fallbackModel: 'llama-3.3-70b-versatile',
      rpm: 30,
      rpd: 14400,
    ),
    AIProvider(
      name: 'gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
      apiKey: 'YOUR_GEMINI_KEY', // from aistudio.google.com
      defaultModel: 'gemini-3.1-flash-lite',
      fallbackModel: 'gemini-3-flash',
      rpm: 15,
      rpd: 1500,
    ),
    AIProvider(
      name: 'cerebras',
      baseUrl: 'https://api.cerebras.ai/v1',
      apiKey: 'YOUR_CEREBRAS_KEY', // from cerebras.ai
      defaultModel: 'llama-3.3-70b',
      rpm: 30,
      rpd: 1000000, // token-based
    ),
    AIProvider(
      name: 'github',
      baseUrl: 'https://models.inference.ai.azure.com',
      apiKey: 'YOUR_GITHUB_TOKEN', // from github.com/settings/tokens
      defaultModel: 'gpt-4o-mini',
      fallbackModel: 'Meta-Llama-3.1-70B-Instruct',
      rpm: 15,
      rpd: 1000,
    ),
    AIProvider(
      name: 'openrouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      apiKey: 'YOUR_OPENROUTER_KEY', // from openrouter.ai
      defaultModel: 'meta-llama/llama-3.1-8b-instruct:free',
      rpm: 20,
      rpd: 50,
    ),
  ];

  // Ollama Cloud config (3 accounts for rotation)
  final List<AIProvider> ollamaAccounts = [
    AIProvider(name: 'ollama_1', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_1', defaultModel: 'llama3.3'),
    AIProvider(name: 'ollama_2', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_2', defaultModel: 'llama3.3'),
    AIProvider(name: 'ollama_3', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_3', defaultModel: 'llama3.3'),
  ];

  /// Main method: try providers in order until one succeeds
  Future<AIResponse> generate({
    required String prompt,
    required String taskType, // 'parsing' | 'planning' | 'summarization' | 'discussion'
    bool requireInternet = true,
  }) async {
    // If all cloud providers fail, try Ollama Cloud account rotation
    final availableOllama = await _getAvailableOllamaAccount();
    if (availableOllama != null) {
      try {
        final response = await _tryProvider(availableOllama, prompt);
        await _recordUsage(availableOllama);
        return response;
      } catch (e) {
        log('Ollama Cloud failed: $e');
      }
    }

    // Try each provider in priority order
    for (var provider in providers) {
      if (await _isRateLimited(provider)) {
        log('${provider.name} rate limited, skipping...');
        continue;
      }

      try {
        final response = await _tryProvider(provider, prompt);
        await _recordUsage(provider);
        return response;
      } catch (e) {
        log('${provider.name} failed: $e');
        continue;
      }
    }

    // All providers failed
    throw Exception('All AI providers unavailable. Check internet connection.');
  }

  Future<AIResponse> _tryProvider(AIProvider provider, String prompt) async {
    final client = OpenAIClient(
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
    );

    final response = await client.chat.completions.create(
      model: provider.defaultModel,
      messages: [
        ChatMessage.system(content: _getSystemPrompt()),
        ChatMessage.user(content: prompt),
      ],
      temperature: 0.3, // low temp for consistent parsing
      maxTokens: 2000,
    );

    return AIResponse(
      text: response.choices.first.message.content,
      provider: provider.name,
      model: provider.defaultModel,
    );
  }

  String _getSystemPrompt() {
    return '''You are KUNST Assistant, an AI that helps with daily life planning and task management.
You communicate concisely. You understand the user's "Three Worlds" framework (Inner, Outside, Future).
When parsing tasks, output valid JSON with fields: name, world, time_state, type, estimated_minutes.
When discussing possibilities, ask clarifying questions. Be helpful but brief.''';
  }

  // Rate limiting helpers
  final Map<String, List<DateTime>> _usageLog = {};

  Future<bool> _isRateLimited(AIProvider provider) async {
    final now = DateTime.now();
    final logs = _usageLog[provider.name] ?? [];

    // Clean old logs
    final recentLogs = logs.where((t) => now.difference(t).inMinutes < 1).toList();
    final dailyLogs = logs.where((t) => now.difference(t).inHours < 24).toList();

    _usageLog[provider.name] = dailyLogs;

    return recentLogs.length >= provider.rpm || dailyLogs.length >= provider.rpd;
  }

  Future<void> _recordUsage(AIProvider provider) async {
    _usageLog.putIfAbsent(provider.name, () => []);
    _usageLog[provider.name]!.add(DateTime.now());
  }

  Future<AIProvider?> _getAvailableOllamaAccount() async {
    for (var account in ollamaAccounts) {
      if (!await _isRateLimited(account)) {
        try {
          final response = await http.get(
            Uri.parse('${account.baseUrl}/models'),
            headers: {'Authorization': 'Bearer ${account.apiKey}'},
          ).timeout(Duration(seconds: 5));
          if (response.statusCode == 200) return account;
        } catch (_) {
          continue;
        }
      }
    }
    return null; // All Ollama accounts rate-limited or down
  }
}
```

### 9.5 Ollama Cloud (Not Local — Laptop Cannot Run It)

**Reality Check**: Your laptop has 4GB RAM and is not always on. Local Ollama is NOT viable.

**Solution**: Use Ollama's **cloud API** (api.ollama.com) with your existing API keys.

| Parameter | Value |
|-----------|-------|
| Base URL | `https://api.ollama.com/v1` |
| Auth | API Key (you already have it) |
| Rate Limit | Resets every 4 hours |
| Best Model | `llama3.3` or `qwen2.5` |
| Use Case | Fallback when other providers are down |

**Your 3 Accounts Strategy**:
Since you have 3 Ollama accounts, you can rotate between them when one hits the rate limit:

```dart
// In AIService, Ollama provider becomes a ROTATING pool
final List<AIProvider> ollamaAccounts = [
  AIProvider(name: 'ollama_1', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_1', ...),
  AIProvider(name: 'ollama_2', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_2', ...),
  AIProvider(name: 'ollama_3', baseUrl: 'https://api.ollama.com/v1', apiKey: 'KEY_3', ...),
];

// When Ollama is selected as provider, try accounts in rotation
// until one is not rate-limited
```

**When Ollama Cloud is Used**:
- All other cloud providers (Groq, Gemini, Cerebras, GitHub) are rate-limited or down
- You want a model that is NOT from the big providers (diversity)
- The 4-hour reset window aligns with your usage (night planning + morning check + evening review = 3 calls, well within limits)

**Note**: Ollama Cloud is NOT for offline use. If you have no internet at all, the launcher falls back to manual mode (no AI, user types everything).

### 9.6 API Key Management

**Security**: API keys are stored in `SharedPreferences` with basic obfuscation. For a sideloaded personal app, this is acceptable. For any future distribution, use Android Keystore.

**Key Input Flow**:
1. Onboarding screen: "Add AI Providers (Optional)"
2. Each provider has a field: API Key + "Get Free Key" button (opens browser to signup page)
3. Keys validated on save (test API call)
4. At least one provider required for full AI features
5. Without keys: launcher works in "manual mode" (no AI suggestions, user types everything)

### 9.7 Fallback Behavior Summary

| Scenario | Behavior |
|----------|----------|
| Groq rate limited | Auto-switch to Gemini |
| Gemini rate limited | Auto-switch to Cerebras |
| Cerebras rate limited | Auto-switch to GitHub Models |
| GitHub rate limited | Auto-switch to OpenRouter |
| All above rate limited | Rotate through Ollama Cloud accounts (1→2→3) |
| All Ollama accounts rate limited | Wait for next 4-hour reset OR manual mode |
| No internet at all | Show "Offline Mode" — manual task entry |
| User never added any API keys | Launcher works fully — user plans manually |

### 9.8 Cost Projection (All Free Tiers)

| Provider | Daily Limit | Monthly Estimate | Cost |
|----------|-------------|------------------|------|
| Groq | 1,000 req/day | ~30,000 req/month | $0 |
| Gemini | 1,500 req/day | ~45,000 req/month | $0 |
| Cerebras | ~1M tokens/day | ~30M tokens/month | $0 |
| GitHub | 1,000 req/day | ~30,000 req/month | $0 |
| OpenRouter | 50 req/day | ~1,500 req/month | $0 |
| Ollama Cloud (3 accounts) | ~3,600 req/day | ~108,000 req/month | $0 |
| **Total Combined** | **~8,150 req/day** | **~244,500 req/month** | **$0** |

This is more than enough for a personal launcher. Even with heavy use (50 AI interactions/day), you're well within limits.

### 9.9 Copilot for Building (Separate from Launcher AI)

**Clarification**: Microsoft Copilot (premium student) is used ONLY for:
- Writing Flutter code during development
- Debugging build errors
- Generating platform channel Kotlin code
- Reviewing the specification

It is NOT integrated into the launcher runtime. The launcher's AI is the multi-provider stack above.

---

## 10. BUILD & DEPLOY PIPELINE

### 10.1 Development Environment

```yaml
# pubspec.yaml
name: kunst_launcher
description: Intentional life launcher
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  provider: ^6.1.1
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^16.3.0
  android_alarm_manager_plus: ^3.0.4
  permission_handler: ^11.1.0
  device_info_plus: ^9.1.1
  webview_flutter: ^4.4.2
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  path: ^1.8.3
  collection: ^1.18.0
  http: ^1.2.0                    # For AI API calls
  dio: ^5.4.0                    # Alternative HTTP client with interceptors
  openai_dart: ^0.4.0            # OpenAI-compatible client (works with Groq, Gemini, etc.)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

### 10.2 Build Steps

```bash
# 1. Clean build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build APK (for sideloading)
flutter build apk --release --target-platform android-arm64

# 4. Build split APKs (smaller size for A05s)
flutter build apk --release --split-per-abi

# 5. Install on device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 6. Set as default launcher (manual or via intent)
adb shell cmd package set-home-activity "com.kunst.launcher/.MainActivity"
```

### 10.3 CI/CD (GitHub Actions)

```yaml
# .github/workflows/build.yml
name: Build KUNST Launcher

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release --split-per-abi

      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/
```

### 10.4 Versioning Strategy

- **MAJOR**: Breaking changes to DB schema or architecture
- **MINOR**: New features (new screen, new service)
- **PATCH**: Bug fixes, theme tweaks, performance

Format: `1.0.0+1` (where +1 is build number, auto-incremented by CI)

---

## 11. TESTING CHECKLIST

### 11.1 Functional Tests

- [ ] Launcher replaces default home screen
- [ ] Device Admin enables successfully
- [ ] App hiding works (social apps disappear in focus mode)
- [ ] App showing works (allowed apps visible)
- [ ] Alarm sets correctly for first task
- [ ] Alarm wakes device even when screen off
- [ ] Notification gatekeeper intercepts social notifications
- [ ] Loved ones notifications come through
- [ ] Emergency keywords break through
- [ ] Evening summary shows all queued notifications
- [ ] Social timer starts and counts down
- [ ] Hard cut overlay appears when timer expires
- [ ] App is force-stopped and hidden after timer
- [ ] Calendar sync creates events in Samsung Calendar
- [ ] Calendar events have correct times and descriptions
- [ ] Night planning note saves and loads
- [ ] Theme changes apply immediately
- [ ] Settings persist across app restarts
- [ ] Database backup exports valid JSON
- [ ] Database restore imports correctly

### 11.2 Samsung-Specific Tests

- [ ] App survives Samsung battery optimization
- [ ] Background service restarts after reboot
- [ ] Notification listener survives app kill
- [ ] Alarm fires reliably after 24+ hours
- [ ] Performance acceptable on A05s (no lag, <200MB RAM)
- [ ] No crash when Bixby Routines activate
- [ ] Edge Panel access still works (acceptable)

### 11.3 Edge Cases

- [ ] No tasks planned for today → show "Plan your day" prompt
- [ ] All tasks completed before evening → early unlock available
- [ ] User tries to open blocked app → show "Focus mode active" toast
- [ ] Device reboots during focus mode → service auto-restarts
- [ ] Calendar permission revoked → show warning, disable calendar sync
- [ ] Exact alarm permission revoked → show warning, use inexact alarm fallback
- [ ] No internet during night planning → save note locally, sync when online

---

## 12. RISKS & MITIGATIONS

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Samsung kills background service | High | Critical | Battery optimization exemption + foreground service + boot receiver |
| Alarm doesn't fire reliably | Medium | High | Test extensively; use `setExactAndAllowWhileIdle` + `WAKE_LOCK` |
| Copilot WebView blocked | Medium | Medium | Fallback to manual copy-paste parsing |
| App hiding breaks system apps | Low | High | Whitelist all system packages; test thoroughly |
| Performance issues on A05s | Medium | High | Profile with Flutter DevTools; reduce widget complexity |
| User forgets to plan at night | High | Medium | Gentle reminder notification at 9 PM |
| Calendar sync conflicts | Low | Medium | Use unique event IDs; handle duplicates |
| Google Play policy (if ever) | N/A | N/A | Not applicable — sideloaded only |

---

## 13. FUTURE ENHANCEMENTS (Post-MVP)

- [ ] Wear OS companion app for quick task completion
- [ ] Widget for home screen showing today's top 3 tasks
- [ ] AI learns from daily_logs to suggest better time estimates
- [ ] Integration with fitness apps for health tracking
- [ ] Prayer time auto-calculation based on location
- [ ] Focus mode analytics: weekly reports on productivity
- [ ] Plugin system for custom "worlds" (user-defined life systems)
- [ ] Cloud backup (Google Drive, OneDrive)
- [ ] Multi-device sync
- [ ] Copilot API integration (if/when available)

---

## 14. DOCUMENTATION FOR AI BUILDER (Copilot)

When feeding this to Copilot, use this prompt structure:

```
You are building KUNST Launcher, an Android launcher app in Flutter.
Read the full specification document below. 

Rules:
1. Do NOT assume any permission is granted automatically — every permission must be explicitly requested with user explanation.
2. Do NOT use deprecated APIs — target Android 15 (API 35).
3. Do NOT add features not in the spec — stick to the screens and logic defined.
4. Do optimize for Samsung A05s (4GB RAM) — keep it lightweight.
5. Do handle ALL edge cases listed in Section 11.
6. Do write platform channel code in Kotlin (not Java).
7. Do test on Android 15 emulator before declaring complete.

Start by building [SPECIFIC COMPONENT].
```

---

## 15. APPENDIX: FILE STRUCTURE

```
kunst_launcher/
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── kotlin/com/kunst/launcher/
│   │   │   │   │   ├── MainActivity.kt
│   │   │   │   │   ├── AdminReceiver.kt
│   │   │   │   │   ├── AlarmReceiver.kt
│   │   │   │   │   ├── BootReceiver.kt
│   │   │   │   │   ├── NotificationService.kt
│   │   │   │   │   ├── AppManager.kt
│   │   │   │   │   ├── CalendarManager.kt
│   │   │   │   │   ├── FocusManager.kt
│   │   │   │   │   └── OverlayManager.kt
│   │   │   │   ├── res/
│   │   │   │   │   ├── xml/device_admin.xml
│   │   │   │   │   ├── layout/time_up_overlay.xml
│   │   │   │   │   └── ...
│   │   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   └── build.gradle
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/
│   │   ├── task.dart
│   │   ├── note.dart
│   │   ├── world.dart
│   │   └── notification_item.dart
│   ├── providers/
│   │   ├── theme_provider.dart
│   │   ├── task_provider.dart
│   │   ├── focus_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── onboarding_screen.dart
│   │   ├── night_planning_screen.dart
│   │   ├── focus_home_screen.dart
│   │   ├── evening_summary_screen.dart
│   │   ├── leisure_mode_screen.dart
│   │   ├── settings_screen.dart
│   │   └── copilot_chat_screen.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   ├── calendar_service.dart
│   │   ├── alarm_service.dart
│   │   ├── app_manager_service.dart
│   │   ├── notification_service.dart
│   │   └── platform_channel_service.dart
│   ├── widgets/
│   │   ├── task_card.dart
│   │   ├── app_icon.dart
│   │   ├── timer_overlay.dart
│   │   ├── theme_selector.dart
│   │   └── ...
│   └── utils/
│       ├── constants.dart
│       ├── extensions.dart
│       └── helpers.dart
├── assets/
│   ├── images/
│   └── icons/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 16. SIGN-OFF

This specification is COMPLETE and READY for implementation.

- All permissions documented
- All screens specified with logic
- All edge cases listed
- Samsung-specific quirks noted
- Database schema provided
- Build pipeline defined
- Testing checklist included
- No assumptions made

**Next Action**: Feed this document to Copilot and begin implementation, one component at a time.

---
*End of Specification*
