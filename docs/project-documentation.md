# LemonTrackAI — Project Documentation

## Slide 6 — Fitur Utama

| Fitur | Penjelasan |
|-------|-----------|
| **AI Chat Assistant** | Chat multi-thread dengan AI (OpenAI, Claude, OpenRouter, Ollama, Custom endpoint). User bisa bertanya, meminta perencanaan, dan ringkasan. |
| **Home Dashboard** | Halaman utama dengan greeting personal, jadwal hari ini, mini week calendar, suggestion chips, dan chat input bar. |
| **Schedule (Kalender)** | Kelola event terjadwal per hari/minggu dengan kategori (School, Work, House, Other). |
| **Time Blocks** | Blok waktu fokus untuk produktivitas — bisa di-link ke task, diberi warna, dan ditandai sebagai focus mode. |
| **Kanban Board** | Board task dengan 3 kolom (To Do, In Progress, Done). Bisa drag, set due date, dan link ke Time Block/Event. |
| **Settings** | Profil user, notifikasi, appearance, Skills (Task Planning, Calendar Management, Homework Tracking, Summaries), AI Engine config, dan manajemen data. |
| **Multi-AI Provider** | Mendukung 5 provider AI: OpenAI, Anthropic Claude, OpenRouter, Custom (OpenAI-compatible), dan Ollama (local). |

---

## Slide 7 — Alur Sistem (Flowchart)

```
┌─────────────┐
│  App Launch  │
└──────┬──────┘
       ▼
┌─────────────┐     ┌──────────────────┐
│  Home Screen │────▶│  User Input Text  │
│  (Dashboard) │     │  (Chat/Suggestion) │
└──────┬──────┘     └────────┬─────────┘
       │                      ▼
       │              ┌──────────────┐
       │              │ Create Thread │
       │              │  + Send Msg   │
       │              └───────┬──────┘
       │                      ▼
       │              ┌──────────────────┐
       │              │  AI Chat Service  │
       │              │  (Dio → API Call) │
       │              └───────┬──────────┘
       │                      ▼
       │              ┌──────────────────┐
       │              │ Save Response &  │
       │              │ Update Local Store│
       │              └──────────────────┘
       │
       ├──────────────────────────────────────┐
       ▼                                      ▼
┌─────────────┐                       ┌─────────────┐
│  Schedule    │                       │   Kanban     │
│  Screen      │                       │   Board      │
│  (Add/View/  │                       │  (Create/    │
│   Edit Event)│                       │   Move/      │
└─────────────┘                       │   Delete)    │
       │                              └──────┬──────┘
       ▼                                     ▼
┌──────────────────────────────────────────────────┐
│            Local Storage Layer                    │
│   (SharedPreferences JSON / Isar DB schemas)      │
└──────────────────────────────────────────────────┘
       ▲
       │
┌──────┴──────┐
│  Time Block  │
│  Screen      │
│  (Focus/     │
│   Plan)      │
└─────────────┘
```

**Ringkasan alur:**
1. User membuka app → Home Screen (greeting + jadwal hari ini)
2. User mengetik pesan / klik suggestion → buat thread baru → kirim ke AI
3. AI Service mengirim request ke provider (OpenAI/Claude/dll) via HTTP
4. Response disimpan ke Local Store → ditampilkan di Chat Screen
5. User bisa navigasi via Drawer ke Schedule, Time Blocks, Kanban, Settings
6. Semua data tersimpan secara lokal (persisten tanpa server)

---

## Slide 9 — Teknologi yang Digunakan

| Kategori | Teknologi | Keterangan |
|----------|-----------|-----------|
| **Framework** | Flutter (Dart SDK ^3.11.0) | Cross-platform UI (Android, iOS, Web) |
| **IDE** | Visual Studio Code | Development environment |
| **State Management** | flutter_riverpod ^2.5.1 | Provider-based reactive state |
| **Database** | Isar ^3.1.0+1 | NoSQL database lokal (high-performance) |
| **Local Storage** | shared_preferences ^2.5.6 | Key-value store untuk config & chat data |
| **HTTP Client** | dio ^5.7.0 + http ^1.2.2 | API calls ke AI providers |
| **AI Integration** | OpenAI, Anthropic Claude, OpenRouter, Ollama, Custom | Multi-provider AI chat |
| **UI Components** | forui ^0.10.0+1 | Component library |
| **Typography** | google_fonts ^6.2.1 | Plus Jakarta Sans font |
| **Speech** | speech_to_text ^7.0.0 | Voice input support |
| **Utilities** | uuid ^4.4.0, intl ^0.20.2, path_provider ^2.1.4 | ID generation, i18n, file paths |
| **Build** | build_runner ^2.4.11 + isar_generator | Code generation untuk Isar schemas |

**Alasan tidak menggunakan Firebase/Cloud Firestore:** Aplikasi ini dirancang sebagai **local-first application** — semua data tersimpan di perangkat menggunakan Isar + SharedPreferences, tanpa perlu koneksi internet untuk fungsi utama (kecuali AI chat). Ini memberikan privasi lebih baik dan offline capability penuh.

---

## Slide 10 — Rancangan Database

**Database Engine:** Isar (NoSQL, embedded, high-performance)

### Collections (Tables):

#### 1. `ChatThread`
| Field | Tipe | Keterangan |
|-------|------|-----------|
| `id` | String (unique index) | UUID primary key |
| `title` | String | Judul percakapan |
| `createdAt` | DateTime (index) | Waktu dibuat |
| `updatedAt` | DateTime (index) | Waktu update terakhir |

#### 2. `Message`
| Field | Tipe | Keterangan |
|-------|------|-----------|
| `id` | String (unique index) | UUID primary key |
| `threadId` | String (index) | FK → ChatThread.id |
| `role` | Enum (user/assistant/system) | Pengirim pesan |
| `content` | String | Isi pesan |
| `timestamp` | DateTime (index) | Waktu pesan |
| `isStreaming` | bool | Status streaming AI |

#### 3. `ScheduleEvent`
| Field | Tipe | Keterangan |
|-------|------|-----------|
| `id` | String (unique index) | UUID primary key |
| `title` | String | Nama event |
| `start` | DateTime (index) | Waktu mulai |
| `end` | DateTime (index) | Waktu selesai |
| `category` | Enum (school/work/house/other) | Kategori event |
| `description` | String? | Deskripsi opsional |

#### 4. `TimeBlock`
| Field | Tipe | Keterangan |
|-------|------|-----------|
| `id` | String (unique index) | UUID primary key |
| `title` | String | Nama blok |
| `start` | DateTime (index) | Waktu mulai |
| `end` | DateTime (index) | Waktu selesai |
| `description` | String? | Deskripsi opsional |
| `linkedTaskId` | String? | FK → KanbanCard.id |
| `colorValue` | int? | Warna blok (ARGB) |
| `isFocus` | bool | Mode fokus |

#### 5. `KanbanCard`
| Field | Tipe | Keterangan |
|-------|------|-----------|
| `id` | String (unique index) | UUID primary key |
| `title` | String | Judul task |
| `description` | String? | Deskripsi opsional |
| `status` | Enum (todo/inProgress/done) | Status kolom |
| `order` | int | Urutan dalam kolom |
| `dueDate` | DateTime? | Deadline opsional |
| `linkedTimeBlockId` | String? | FK → TimeBlock.id |
| `linkedEventId` | String? | FK → ScheduleEvent.id |

### Relasi:
```
ChatThread 1───* Message (via threadId)
KanbanCard *───1 TimeBlock (via linkedTimeBlockId)
KanbanCard *───1 ScheduleEvent (via linkedEventId)
TimeBlock  *───1 KanbanCard (via linkedTaskId)
```

---

## Slide 11 — Arsitektur dan Struktur Aplikasi

**Pattern:** Feature-First Architecture dengan Clean Architecture layering

### Folder Structure:
```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Route definitions
├── core/                        # Shared infrastructure
│   ├── constants/               # App constants
│   ├── database/                # Isar DB service + schemas
│   │   ├── isar_service.dart
│   │   └── schemas/             # Isar collection definitions
│   ├── storage/                 # LocalStore (SharedPreferences)
│   ├── theme/                   # AppTheme + AppColors
│   └── utils/                   # Date utilities
├── features/                    # Feature modules
│   ├── chat/                    # AI Chat feature
│   │   ├── domain/              # Entities (ChatThread, Message)
│   │   ├── data/                # Repositories + AI Service
│   │   │   ├── ai_chat_service.dart
│   │   │   ├── chat_repository.dart (abstract)
│   │   │   └── local/           # LocalChatRepository impl
│   │   └── presentation/        # UI + Controller
│   │       ├── chat_screen.dart
│   │       ├── chat_controller.dart
│   │       └── widgets/
│   ├── home/                    # Home dashboard
│   │   └── presentation/
│   ├── schedule/                # Calendar/Schedule feature
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── timeblock/               # Time blocking feature
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── kanban/                  # Kanban board feature
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── settings/                # Settings feature
│       └── presentation/
├── providers/                   # Global Riverpod providers
│   ├── ai_engine_provider.dart
│   ├── repository_providers.dart
│   ├── user_provider.dart
│   ├── theme_provider.dart
│   ├── notifications_provider.dart
│   └── shared_prefs_provider.dart
└── shared/                      # Shared widgets
    └── widgets/
        ├── lemon_drawer.dart    # Navigation drawer
        └── chat_input_bar.dart  # Reusable input
```

### Navigation:
- **Route-based** (`Navigator.pushNamed`) dengan named routes
- **Drawer** sebagai primary navigation (Home, Schedule, Time Blocks, Kanban, Settings, Chat history)

### State Management:
- **Riverpod** (StateNotifierProvider, FutureProvider, family)
- Controllers per feature (chat_controller, schedule_controller, kanban_controller, time_block_controller)

### Data Flow:
```
UI (Screen/Widget)
    ↕ (watch/read)
Riverpod Provider (Controller)
    ↕ (call)
Repository (abstract interface)
    ↕ (implement)
Local Repository (Isar / SharedPreferences)
    ↕ (for chat)
AI Service (Dio HTTP → External API)
```
